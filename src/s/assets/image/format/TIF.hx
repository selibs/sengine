package s.assets.image.format;

import haxe.ds.IntMap;
import haxe.io.Bytes;

private typedef TiffField = {
	var type:Int;
	var count:Int;
	var dataOffset:Int;
}

class TIF extends ImageDecoder {
	static inline final tagImageWidth:Int = 256;
	static inline final tagImageLength:Int = 257;
	static inline final tagBitsPerSample:Int = 258;
	static inline final tagCompression:Int = 259;
	static inline final tagPhotometric:Int = 262;
	static inline final tagOrientation:Int = 274;
	static inline final tagStripOffsets:Int = 273;
	static inline final tagSamplesPerPixel:Int = 277;
	static inline final tagRowsPerStrip:Int = 278;
	static inline final tagStripByteCounts:Int = 279;
	static inline final tagPlanarConfiguration:Int = 284;
	static inline final tagPredictor:Int = 317;
	static inline final tagColorMap:Int = 320;
	static inline final tagExtraSamples:Int = 338;
	static inline final tagSampleFormat:Int = 339;
	static inline final tagTileWidth:Int = 322;
	static inline final tagTileLength:Int = 323;

	static inline final compressionNone:Int = 1;
	static inline final compressionLzw:Int = 5;
	static inline final compressionDeflate:Int = 8;
	static inline final compressionPackBits:Int = 32773;
	static inline final compressionDeflateOld:Int = 32946;

	static inline final photometricWhiteIsZero:Int = 0;
	static inline final photometricBlackIsZero:Int = 1;
	static inline final photometricRgb:Int = 2;
	static inline final photometricPalette:Int = 3;
	static inline final photometricSeparated:Int = 5;

	static inline final sampleFormatUInt:Int = 1;
	static inline final sampleFormatFloat:Int = 3;

	var littleEndian = true;
	var sourceWidth:Int = 0;
	var sourceHeight:Int = 0;
	var bitsPerSample:Int = 8;
	var samplesPerPixel:Int = 1;
	var sampleFormat:Int = sampleFormatUInt;
	var photometric:Int = photometricBlackIsZero;
	var planarConfiguration:Int = 1;
	var predictor:Int = 1;
	var orientation:Int = 1;
	var alphaSampleIndex:Int = -1;
	var chunky:Bytes = null;
	var planes:Array<Bytes> = null;
	var chunkyRowBytes:Int = 0;
	var planeRowBytes:Int = 0;
	var palette:Bytes = null;

	public function decode(bytes:Bytes):Void {
		chunky = null;
		planes = null;
		palette = null;

		DecodeTools.ensureAvailable(bytes, 0, 8, "TIFF header");
		final order = DecodeTools.readTag(bytes, 0, 2);
		littleEndian = switch order {
			case "II": true;
			case "MM": false;
			case _: DecodeTools.fail("Invalid TIFF byte order");
		}

		final version = readU16(bytes, 2);
		if (version == 43)
			DecodeTools.fail("BigTIFF is not supported");
		if (version != 42)
			DecodeTools.fail('Invalid TIFF version: $version');

		final ifdOffset = readU32(bytes, 4);
		final fields = readIfd(bytes, ifdOffset);
		if (fields.exists(tagTileWidth) || fields.exists(tagTileLength))
			DecodeTools.fail("Tiled TIFF images are not supported");

		sourceWidth = readRequiredInt(bytes, fields, tagImageWidth, "ImageWidth");
		sourceHeight = readRequiredInt(bytes, fields, tagImageLength, "ImageLength");
		if (sourceWidth <= 0 || sourceHeight <= 0)
			DecodeTools.fail('Invalid TIFF size: ${sourceWidth}x$sourceHeight');

		final bits = fields.get(tagBitsPerSample);
		final bitsList = bits != null ? readIntArray(bytes, bits) : [1];
		bitsPerSample = bitsList[0];
		for (value in bitsList) {
			if (value != bitsPerSample)
				DecodeTools.fail("TIFF images with mixed BitsPerSample are not supported");
		}

		photometric = readOptionalInt(bytes, fields, tagPhotometric, photometricBlackIsZero);
		final compression = readOptionalInt(bytes, fields, tagCompression, compressionNone);
		orientation = readOptionalInt(bytes, fields, tagOrientation, 1);
		samplesPerPixel = readOptionalInt(bytes, fields, tagSamplesPerPixel, defaultSamplesPerPixel(photometric));
		planarConfiguration = readOptionalInt(bytes, fields, tagPlanarConfiguration, 1);
		predictor = readOptionalInt(bytes, fields, tagPredictor, 1);

		final sampleFormatField = fields.get(tagSampleFormat);
		if (sampleFormatField != null) {
			final sampleFormats = readIntArray(bytes, sampleFormatField);
			sampleFormat = sampleFormats[0];
			for (value in sampleFormats) {
				if (value != sampleFormat)
					DecodeTools.fail("TIFF images with mixed SampleFormat are not supported");
			}
		}

		if (sampleFormat != sampleFormatUInt && sampleFormat != sampleFormatFloat)
			DecodeTools.fail('Unsupported TIFF SampleFormat: $sampleFormat');

		if (bitsPerSample != 1 && bitsPerSample != 2 && bitsPerSample != 4 && bitsPerSample != 8 && bitsPerSample != 16 && bitsPerSample != 32)
			DecodeTools.fail('Unsupported TIFF bit depth: $bitsPerSample');

		if (sampleFormat == sampleFormatFloat && bitsPerSample != 32)
			DecodeTools.fail("Only 32-bit float TIFF samples are supported");
		if (samplesPerPixel > 1 && bitsPerSample < 8)
			DecodeTools.fail("Packed multi-sample TIFF images are not supported");

		final colorMapField = fields.get(tagColorMap);
		if (photometric == photometricPalette) {
			if (colorMapField == null)
				DecodeTools.fail("Palette TIFF image is missing ColorMap");
			palette = readColorMap(bytes, colorMapField);
		}

		final stripOffsetsField = getRequiredField(fields, tagStripOffsets, "StripOffsets");
		final stripByteCountsField = getRequiredField(fields, tagStripByteCounts, "StripByteCounts");
		final stripOffsets = readIntArray(bytes, stripOffsetsField);
		final stripByteCounts = readIntArray(bytes, stripByteCountsField);
		if (stripOffsets.length != stripByteCounts.length)
			DecodeTools.fail("TIFF StripOffsets and StripByteCounts length mismatch");

		final rowsPerStrip = readOptionalInt(bytes, fields, tagRowsPerStrip, sourceHeight);
		final stripsPerPlane = Std.int((sourceHeight + rowsPerStrip - 1) / rowsPerStrip);
		final expectedStrips = planarConfiguration == 2 ? stripsPerPlane * samplesPerPixel : stripsPerPlane;
		if (stripOffsets.length < expectedStrips)
			DecodeTools.fail('TIFF strip count is too small: expected $expectedStrips, got ${stripOffsets.length}');

		alphaSampleIndex = defaultAlphaIndex(bytes, fields);

		if (planarConfiguration == 1) {
			chunkyRowBytes = ((sourceWidth * samplesPerPixel * bitsPerSample) + 7) >> 3;
			chunky = Bytes.alloc(chunkyRowBytes * sourceHeight);
			decodeChunky(bytes, stripOffsets, stripByteCounts, rowsPerStrip, compression);
		} else if (planarConfiguration == 2) {
			planeRowBytes = ((sourceWidth * bitsPerSample) + 7) >> 3;
			planes = [];
			for (_ in 0...samplesPerPixel)
				planes.push(Bytes.alloc(planeRowBytes * sourceHeight));
			decodePlanar(bytes, stripOffsets, stripByteCounts, rowsPerStrip, compression, stripsPerPlane);
		} else {
			DecodeTools.fail('Unsupported TIFF PlanarConfiguration: $planarConfiguration');
		}

		final rotated = orientation >= 5 && orientation <= 8;
		width = rotated ? sourceHeight : sourceWidth;
		height = rotated ? sourceWidth : sourceHeight;
		pixels = Bytes.alloc(width * height * 4);

		switch photometric {
			case photometricWhiteIsZero, photometricBlackIsZero:
				writeGray();
			case photometricRgb:
				writeRgb();
			case photometricPalette:
				writePalette();
			case photometricSeparated:
				writeCmyk();
			case _:
				DecodeTools.fail('Unsupported TIFF photometric interpretation: $photometric');
		}

		finish();
	}

	function decodeChunky(bytes:Bytes, stripOffsets:Array<Int>, stripByteCounts:Array<Int>, rowsPerStrip:Int, compression:Int):Void {
		for (strip in 0...stripOffsets.length) {
			final row = strip * rowsPerStrip;
			if (row >= sourceHeight)
				break;
			final rows = Std.int(Math.min(rowsPerStrip, sourceHeight - row));
			final expectedLength = chunkyRowBytes * rows;
			final data = decodeStrip(bytes, stripOffsets[strip], stripByteCounts[strip], expectedLength, compression);
			if (predictor == 2)
				applyPredictor(data, rows, chunkyRowBytes, samplesPerPixel);
			chunky.blit(row * chunkyRowBytes, data, 0, expectedLength);
		}
	}

	function decodePlanar(bytes:Bytes, stripOffsets:Array<Int>, stripByteCounts:Array<Int>, rowsPerStrip:Int, compression:Int, stripsPerPlane:Int):Void {
		for (sample in 0...samplesPerPixel) {
			final plane = planes[sample];
			for (strip in 0...stripsPerPlane) {
				final stripIndex = sample * stripsPerPlane + strip;
				final row = strip * rowsPerStrip;
				if (row >= sourceHeight)
					break;
				final rows = Std.int(Math.min(rowsPerStrip, sourceHeight - row));
				final expectedLength = planeRowBytes * rows;
				final data = decodeStrip(bytes, stripOffsets[stripIndex], stripByteCounts[stripIndex], expectedLength, compression);
				if (predictor == 2)
					applyPredictor(data, rows, planeRowBytes, 1);
				plane.blit(row * planeRowBytes, data, 0, expectedLength);
			}
		}
	}

	function decodeStrip(bytes:Bytes, offset:Int, length:Int, expectedLength:Int, compression:Int):Bytes {
		DecodeTools.ensureAvailable(bytes, offset, length, "TIFF strip");
		final data = bytes.sub(offset, length);
		final out = switch compression {
			case compressionNone:
				if (length < expectedLength)
					DecodeTools.fail("TIFF raw strip is shorter than expected");
				final copy = Bytes.alloc(expectedLength);
				copy.blit(0, data, 0, expectedLength);
				copy;
			case compressionPackBits:
				DecodeTools.packBitsDecode(data, expectedLength);
			case compressionDeflate, compressionDeflateOld:
				final inflated = DecodeTools.inflate(data);
				if (inflated.length < expectedLength)
					DecodeTools.fail("TIFF deflate strip is shorter than expected");
				final copy = Bytes.alloc(expectedLength);
				copy.blit(0, inflated, 0, expectedLength);
				copy;
			case compressionLzw:
				decodeLzw(data, expectedLength);
			case _:
				DecodeTools.fail('Unsupported TIFF compression: $compression');
		}
		return out;
	}

	function applyPredictor(bytes:Bytes, rows:Int, rowBytes:Int, sampleStride:Int):Void {
		if (predictor != 2)
			return;

		switch bitsPerSample {
			case 8:
				for (row in 0...rows) {
					final rowOffset = row * rowBytes;
					for (i in sampleStride...rowBytes)
						bytes.set(rowOffset + i, (bytes.get(rowOffset + i) + bytes.get(rowOffset + i - sampleStride)) & 0xff);
				}
			case 16:
				final byteStride = sampleStride * 2;
				for (row in 0...rows) {
					final rowOffset = row * rowBytes;
					var i = byteStride;
					while (i < rowBytes) {
						final current = readU16(bytes, rowOffset + i);
						final previous = readU16(bytes, rowOffset + i - byteStride);
						writeU16(bytes, rowOffset + i, (current + previous) & 0xffff);
						i += 2;
					}
				}
			case _:
				DecodeTools.fail('Unsupported TIFF predictor depth: $bitsPerSample');
		}
	}

	function writeGray():Void {
		for (y in 0...sourceHeight) {
			for (x in 0...sourceWidth) {
				var gray = readByteSample(0, x, y);
				if (photometric == photometricWhiteIsZero)
					gray = 255 - gray;
				final alpha = alphaSampleIndex >= 0 ? readByteSample(alphaSampleIndex, x, y) : 255;
				writePixel(x, y, gray, gray, gray, alpha);
			}
		}
	}

	function writeRgb():Void {
		if (samplesPerPixel < 3)
			DecodeTools.fail("TIFF RGB image is missing color channels");

		for (y in 0...sourceHeight) {
			for (x in 0...sourceWidth) {
				writePixel(x, y, readByteSample(0, x, y), readByteSample(1, x, y), readByteSample(2, x, y),
					alphaSampleIndex >= 0 ? readByteSample(alphaSampleIndex, x, y) : 255);
			}
		}
	}

	function writePalette():Void {
		for (y in 0...sourceHeight) {
			for (x in 0...sourceWidth) {
				final index = readIntSample(0, x, y);
				if (index < 0 || index * 4 + 3 >= palette.length)
					DecodeTools.fail('TIFF palette index out of range: $index');
				writePixel(x, y, palette.get(index * 4 + 0), palette.get(index * 4 + 1), palette.get(index * 4 + 2),
					alphaSampleIndex >= 0 ? readByteSample(alphaSampleIndex, x, y) : 255);
			}
		}
	}

	function writeCmyk():Void {
		if (samplesPerPixel < 4)
			DecodeTools.fail("TIFF CMYK image is missing color channels");

		for (y in 0...sourceHeight) {
			for (x in 0...sourceWidth) {
				final c = readUnitSample(0, x, y);
				final m = readUnitSample(1, x, y);
				final yv = readUnitSample(2, x, y);
				final k = readUnitSample(3, x, y);
				writePixel(x, y, DecodeTools.clampByte((1.0 - c) * (1.0 - k) * 255.0), DecodeTools.clampByte((1.0 - m) * (1.0 - k) * 255.0),
					DecodeTools.clampByte((1.0 - yv) * (1.0 - k) * 255.0), alphaSampleIndex >= 0 ? readByteSample(alphaSampleIndex, x, y) : 255);
			}
		}
	}

	inline function writePixel(sourceX:Int, sourceY:Int, r:Int, g:Int, b:Int, a:Int):Void {
		final position = orient(sourceX, sourceY);
		final offset = (position.y * width + position.x) * 4;
		pixels.set(offset + 0, r);
		pixels.set(offset + 1, g);
		pixels.set(offset + 2, b);
		pixels.set(offset + 3, a);
	}

	function orient(x:Int, y:Int):{x:Int, y:Int} {
		return switch orientation {
			case 2: {x: sourceWidth - 1 - x, y: y};
			case 3: {x: sourceWidth - 1 - x, y: sourceHeight - 1 - y};
			case 4: {x: x, y: sourceHeight - 1 - y};
			case 5: {x: y, y: x};
			case 6: {x: sourceHeight - 1 - y, y: x};
			case 7: {x: sourceHeight - 1 - y, y: sourceWidth - 1 - x};
			case 8: {x: y, y: sourceWidth - 1 - x};
			case _: {x: x, y: y};
		}
	}

	function readIntSample(sample:Int, x:Int, y:Int):Int {
		final data = sampleData(sample);
		final rowBytes = sampleRowBytes(sample);
		final rowOffset = y * rowBytes;

		return if (bitsPerSample < 8) {
			if (sample != 0)
				DecodeTools.fail("Packed TIFF extra channels are not supported");
			DecodeTools.unpackBitsAt(data, rowOffset, bitsPerSample, x);
		} else if (bitsPerSample == 8) {
			data.get(rowOffset + x * sampleStride() + sampleByteOffset(sample));
		} else if (bitsPerSample == 16) {
			readU16(data, rowOffset + (x * sampleStride() + sampleByteOffset(sample)) * 2);
		} else if (bitsPerSample == 32 && sampleFormat == sampleFormatUInt) {
			readU32(data, rowOffset + (x * sampleStride() + sampleByteOffset(sample)) * 4);
		} else {
			final value = readUnitSample(sample, x, y);
			value <= 0 ? 0 : Std.int(value);
		}
	}

	function readUnitSample(sample:Int, x:Int, y:Int):Float {
		final data = sampleData(sample);
		final rowBytes = sampleRowBytes(sample);
		final rowOffset = y * rowBytes;

		return switch sampleFormat {
			case sampleFormatUInt:
				switch bitsPerSample {
					case 1, 2, 4:
						DecodeTools.unpackBitsAt(data, rowOffset, bitsPerSample, x);
					case 8:
						data.get(rowOffset + x * sampleStride() + sampleByteOffset(sample)) / 255.0;
					case 16:
						readU16(data, rowOffset + (x * sampleStride() + sampleByteOffset(sample)) * 2) / 65535.0;
					case 32:
						final value = readU32(data, rowOffset + (x * sampleStride() + sampleByteOffset(sample)) * 4);
						(value < 0 ? value + 4294967296.0 : value) / 4294967295.0;
					case _:
						DecodeTools.fail('Unsupported TIFF integer sample depth: $bitsPerSample');
				}
			case sampleFormatFloat:
				final offset = rowOffset + (x * sampleStride() + sampleByteOffset(sample)) * 4;
				final value = littleEndian ? DecodeTools.float32LE(data, offset) : DecodeTools.float32BE(data, offset);
				if (Math.isNaN(value) || value < 0) 0.0 else value;
			case _:
				DecodeTools.fail('Unsupported TIFF SampleFormat: $sampleFormat');
		}
	}

	function readByteSample(sample:Int, x:Int, y:Int):Int {
		return if (sampleFormat == sampleFormatUInt) {
			switch bitsPerSample {
				case 1, 2, 4, 8, 16:
					DecodeTools.scaleToByte(readIntSample(sample, x, y), bitsPerSample > 16 ? 16 : bitsPerSample);
				case 32:
					final value = readUnitSample(sample, x, y);
					value <= 1.0 ? DecodeTools.clampByte(value * 255.0) : DecodeTools.toneMap(value);
				case _:
					DecodeTools.fail('Unsupported TIFF sample depth: $bitsPerSample');
			}
		} else {
			final value = readUnitSample(sample, x, y);
			value <= 1.0 ? DecodeTools.clampByte(value * 255.0) : DecodeTools.toneMap(value);
		}
	}

	inline function sampleData(sample:Int):Bytes
		return chunky != null ? chunky : planes[sample];

	inline function sampleRowBytes(sample:Int):Int
		return chunky != null ? chunkyRowBytes : planeRowBytes;

	inline function sampleStride():Int
		return chunky != null ? samplesPerPixel : 1;

	inline function sampleByteOffset(sample:Int):Int
		return chunky != null ? sample : 0;

	function defaultAlphaIndex(bytes:Bytes, fields:IntMap<TiffField>):Int {
		final extraField = fields.get(tagExtraSamples);
		if (extraField == null)
			return samplesPerPixel == 2 || samplesPerPixel == 4 || samplesPerPixel == 5 ? samplesPerPixel - 1 : -1;
		final extra = readIntArray(bytes, extraField);
		return extra.length > 0 ? samplesPerPixel - extra.length : -1;
	}

	function defaultSamplesPerPixel(photometric:Int):Int {
		return switch photometric {
			case photometricRgb: 3;
			case photometricSeparated: 4;
			case _: 1;
		}
	}

	function readColorMap(bytes:Bytes, field:TiffField):Bytes {
		final values = readIntArray(bytes, field);
		if ((values.length % 3) != 0)
			DecodeTools.fail("Invalid TIFF ColorMap length");
		final size = Std.int(values.length / 3);
		final palette = Bytes.alloc(size * 4);
		for (i in 0...size) {
			palette.set(i * 4 + 0, DecodeTools.scaleToByte(values[i], 16));
			palette.set(i * 4 + 1, DecodeTools.scaleToByte(values[i + size], 16));
			palette.set(i * 4 + 2, DecodeTools.scaleToByte(values[i + size * 2], 16));
			palette.set(i * 4 + 3, 255);
		}
		return palette;
	}

	function readIfd(bytes:Bytes, offset:Int):IntMap<TiffField> {
		DecodeTools.ensureAvailable(bytes, offset, 2, "TIFF IFD entry count");
		final count = readU16(bytes, offset);
		DecodeTools.ensureAvailable(bytes, offset + 2, count * 12 + 4, "TIFF IFD");

		final fields = new IntMap<TiffField>();
		for (i in 0...count) {
			final entryOffset = offset + 2 + i * 12;
			final tag = readU16(bytes, entryOffset);
			final type = readU16(bytes, entryOffset + 2);
			final valueCount = readU32(bytes, entryOffset + 4);
			final size = typeSize(type);
			final totalSize = size * valueCount;
			final dataOffset = totalSize <= 4 ? entryOffset + 8 : readU32(bytes, entryOffset + 8);
			DecodeTools.ensureAvailable(bytes, dataOffset, totalSize, 'TIFF tag $tag');
			fields.set(tag, {
				type: type,
				count: valueCount,
				dataOffset: dataOffset
			});
		}
		return fields;
	}

	function getRequiredField(fields:IntMap<TiffField>, tag:Int, label:String):TiffField {
		final field = fields.get(tag);
		if (field == null)
			DecodeTools.fail('Missing TIFF field: $label');
		return field;
	}

	function readRequiredInt(bytes:Bytes, fields:IntMap<TiffField>, tag:Int, label:String):Int {
		return readFieldInt(bytes, getRequiredField(fields, tag, label), 0);
	}

	function readOptionalInt(bytes:Bytes, fields:IntMap<TiffField>, tag:Int, fallback:Int):Int {
		final field = fields.get(tag);
		return field == null ? fallback : readFieldInt(bytes, field, 0);
	}

	function readIntArray(bytes:Bytes, field:TiffField):Array<Int> {
		final values = new Array<Int>();
		for (i in 0...field.count)
			values.push(readFieldInt(bytes, field, i));
		return values;
	}

	function readFieldInt(bytes:Bytes, field:TiffField, index:Int):Int {
		if (index < 0 || index >= field.count)
			DecodeTools.fail('TIFF field index out of range: $index');
		final offset = field.dataOffset + index * typeSize(field.type);
		return switch field.type {
			case 1, 7:
				bytes.get(offset);
			case 3:
				readU16(bytes, offset);
			case 4:
				readU32(bytes, offset);
			case 6:
				final value = bytes.get(offset);
				(value & 0x80) != 0 ? value - 0x100 : value;
			case 8:
				readS16(bytes, offset);
			case 9:
				readS32(bytes, offset);
			case 11:
				Std.int(littleEndian ? DecodeTools.float32LE(bytes, offset) : DecodeTools.float32BE(bytes, offset));
			case _:
				DecodeTools.fail('Unsupported TIFF field type: ${field.type}');
		}
	}

	function typeSize(type:Int):Int {
		return switch type {
			case 1, 2, 6, 7: 1;
			case 3, 8: 2;
			case 4, 9, 11: 4;
			case 5, 10, 12: 8;
			case _: DecodeTools.fail('Unsupported TIFF field type: $type');
		}
	}

	function decodeLzw(bytes:Bytes, expectedLength:Int):Bytes {
		final output = Bytes.alloc(expectedLength);
		final dictionary = new Array<Array<Int>>();
		var bitPosition = 0;
		var codeSize = 9;
		var nextCode = 258;
		var previous:Array<Int> = null;
		var outOffset = 0;

		function resetDictionary():Void {
			dictionary.resize(258);
			for (i in 0...256)
				dictionary[i] = [i];
			dictionary[256] = [];
			dictionary[257] = [];
			codeSize = 9;
			nextCode = 258;
			previous = null;
		}

		function readCode():Int {
			var value = 0;
			for (i in 0...codeSize) {
				final bitIndex = bitPosition + i;
				final byteIndex = bitIndex >> 3;
				if (byteIndex >= bytes.length)
					return -1;
				final shift = 7 - (bitIndex & 7);
				value = (value << 1) | ((bytes.get(byteIndex) >> shift) & 1);
			}
			bitPosition += codeSize;
			return value;
		}

		resetDictionary();

		while (outOffset < expectedLength) {
			final code = readCode();
			if (code < 0 || code == 257)
				break;
			if (code == 256) {
				resetDictionary();
				continue;
			}

			var entry:Array<Int> = null;
			if (code < dictionary.length && dictionary[code] != null) {
				entry = dictionary[code];
			} else if (code == nextCode && previous != null) {
				entry = previous.copy();
				entry.push(previous[0]);
			} else {
				DecodeTools.fail('Invalid TIFF LZW code: $code');
			}

			for (value in entry) {
				if (outOffset >= expectedLength)
					break;
				output.set(outOffset++, value);
			}

			if (previous != null && nextCode < 4096) {
				final newEntry = previous.copy();
				newEntry.push(entry[0]);
				if (dictionary.length <= nextCode)
					dictionary.resize(nextCode + 1);
				dictionary[nextCode++] = newEntry;
				if (nextCode == (1 << codeSize) && codeSize < 12)
					codeSize++;
			}

			previous = entry;
		}

		if (outOffset < expectedLength)
			DecodeTools.fail('TIFF LZW stream is truncated: expected $expectedLength bytes, got $outOffset');
		return output;
	}

	inline function readU16(bytes:Bytes, offset:Int):Int
		return littleEndian ? DecodeTools.u16LE(bytes, offset) : DecodeTools.u16BE(bytes, offset);

	inline function readS16(bytes:Bytes, offset:Int):Int
		return littleEndian ? DecodeTools.s16LE(bytes, offset) : DecodeTools.s16BE(bytes, offset);

	inline function readU32(bytes:Bytes, offset:Int):Int
		return littleEndian ? DecodeTools.u32LE(bytes, offset) : DecodeTools.u32BE(bytes, offset);

	inline function readS32(bytes:Bytes, offset:Int):Int
		return littleEndian ? DecodeTools.i32LE(bytes, offset) : DecodeTools.i32BE(bytes, offset);

	inline function writeU16(bytes:Bytes, offset:Int, value:Int):Void {
		if (littleEndian) {
			bytes.set(offset + 0, value & 0xff);
			bytes.set(offset + 1, (value >> 8) & 0xff);
		} else {
			bytes.set(offset + 0, (value >> 8) & 0xff);
			bytes.set(offset + 1, value & 0xff);
		}
	}
}
