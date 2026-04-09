package s.assets.internal.image.format;

import haxe.io.Bytes;

class PSD extends ImageDecoder {
	static inline final compressionRaw:Int = 0;
	static inline final compressionRle:Int = 1;
	static inline final compressionZip:Int = 2;
	static inline final compressionZipPrediction:Int = 3;

	static inline final colorModeBitmap:Int = 0;
	static inline final colorModeGrayscale:Int = 1;
	static inline final colorModeIndexed:Int = 2;
	static inline final colorModeRgb:Int = 3;
	static inline final colorModeCmyk:Int = 4;

	public function decode(bytes:Bytes):Void {
		DecodeTools.ensureAvailable(bytes, 0, 26, "PSD header");
		if (DecodeTools.readTag(bytes, 0, 4) != "8BPS")
			DecodeTools.fail("Invalid PSD signature");

		final version = DecodeTools.u16BE(bytes, 4);
		if (version != 1)
			DecodeTools.fail('Unsupported PSD version: $version');

		final channels = DecodeTools.u16BE(bytes, 12);
		height = DecodeTools.u32BE(bytes, 14);
		width = DecodeTools.u32BE(bytes, 18);
		final depth = DecodeTools.u16BE(bytes, 22);
		final colorMode = DecodeTools.u16BE(bytes, 24);

		if (width <= 0 || height <= 0)
			DecodeTools.fail('Invalid PSD size: ${width}x$height');
		if (channels <= 0)
			DecodeTools.fail("PSD must have at least one channel");

		var offset = 26;

		final colorModeDataLength = DecodeTools.u32BE(bytes, offset);
		offset += 4;
		DecodeTools.ensureAvailable(bytes, offset, colorModeDataLength, "PSD color mode data");
		final colorModeData = bytes.sub(offset, colorModeDataLength);
		offset += colorModeDataLength;

		final imageResourcesLength = DecodeTools.u32BE(bytes, offset);
		offset += 4;
		DecodeTools.ensureAvailable(bytes, offset, imageResourcesLength, "PSD image resources");
		offset += imageResourcesLength;

		final layerMaskLength = DecodeTools.u32BE(bytes, offset);
		offset += 4;
		DecodeTools.ensureAvailable(bytes, offset, layerMaskLength, "PSD layer and mask data");
		offset += layerMaskLength;

		DecodeTools.ensureAvailable(bytes, offset, 2, "PSD compression");
		final compression = DecodeTools.u16BE(bytes, offset);
		offset += 2;

		final rowBytes = ((width * depth) + 7) >> 3;
		final planeSize = rowBytes * height;
		final planes = switch compression {
			case compressionRaw:
				decodeRaw(bytes, offset, channels, planeSize);
			case compressionRle:
				decodeRle(bytes, offset, channels, rowBytes);
			case compressionZip:
				decodeZip(bytes, offset, channels, planeSize);
			case compressionZipPrediction:
				decodeZipPredicted(bytes, offset, channels, rowBytes, planeSize, depth);
			case _:
				DecodeTools.fail('Unsupported PSD compression: $compression');
		}

		final palette = colorMode == colorModeIndexed ? readPalette(colorModeData) : null;
		pixels = Bytes.alloc(width * height * 4);

		switch colorMode {
			case colorModeBitmap:
				writeBitmap(planes);
			case colorModeGrayscale:
				writeGrayscale(planes, depth);
			case colorModeIndexed:
				writeIndexed(planes, depth, palette);
			case colorModeRgb:
				writeRgb(planes, depth);
			case colorModeCmyk:
				writeCmyk(planes, depth);
			case _:
				DecodeTools.fail('Unsupported PSD color mode: $colorMode');
		}

		finish();
	}

	function decodeRaw(bytes:Bytes, offset:Int, channels:Int, planeSize:Int):Array<Bytes> {
		DecodeTools.ensureAvailable(bytes, offset, channels * planeSize, "PSD raw image data");
		final planes = new Array<Bytes>();
		for (channel in 0...channels) {
			final plane = Bytes.alloc(planeSize);
			plane.blit(0, bytes, offset + channel * planeSize, planeSize);
			planes.push(plane);
		}
		return planes;
	}

	function decodeRle(bytes:Bytes, offset:Int, channels:Int, rowBytes:Int):Array<Bytes> {
		final rowCount = channels * height;
		DecodeTools.ensureAvailable(bytes, offset, rowCount * 2, "PSD RLE byte counts");

		final lengths = new Array<Int>();
		for (i in 0...rowCount) {
			lengths.push(DecodeTools.u16BE(bytes, offset));
			offset += 2;
		}

		final planes = new Array<Bytes>();
		for (channel in 0...channels) {
			final plane = Bytes.alloc(rowBytes * height);
			for (y in 0...height) {
				final compressedLength = lengths[channel * height + y];
				DecodeTools.ensureAvailable(bytes, offset, compressedLength, "PSD RLE row");
				final row = DecodeTools.packBitsDecode(bytes.sub(offset, compressedLength), rowBytes);
				plane.blit(y * rowBytes, row, 0, rowBytes);
				offset += compressedLength;
			}
			planes.push(plane);
		}
		return planes;
	}

	function decodeZip(bytes:Bytes, offset:Int, channels:Int, planeSize:Int):Array<Bytes> {
		DecodeTools.ensureAvailable(bytes, offset, bytes.length - offset, "PSD ZIP data");
		final inflated = DecodeTools.inflate(bytes.sub(offset, bytes.length - offset));
		final expectedLength = channels * planeSize;
		if (inflated.length < expectedLength)
			DecodeTools.fail('PSD ZIP stream is truncated: expected $expectedLength bytes, got ${inflated.length}');

		final planes = new Array<Bytes>();
		for (channel in 0...channels) {
			final plane = Bytes.alloc(planeSize);
			plane.blit(0, inflated, channel * planeSize, planeSize);
			planes.push(plane);
		}
		return planes;
	}

	function decodeZipPredicted(bytes:Bytes, offset:Int, channels:Int, rowBytes:Int, planeSize:Int, depth:Int):Array<Bytes> {
		final planes = decodeZip(bytes, offset, channels, planeSize);
		for (plane in planes)
			applyZipPrediction(plane, rowBytes, depth);
		return planes;
	}

	function readPalette(bytes:Bytes):Bytes {
		if (bytes.length < 768)
			DecodeTools.fail("PSD indexed palette is missing or incomplete");

		final entries = 256;
		final palette = Bytes.alloc(entries * 4);
		for (i in 0...entries) {
			palette.set(i * 4 + 0, bytes.get(i));
			palette.set(i * 4 + 1, bytes.get(i + 256));
			palette.set(i * 4 + 2, bytes.get(i + 512));
			palette.set(i * 4 + 3, 255);
		}
		return palette;
	}

	function writeBitmap(planes:Array<Bytes>):Void {
		final plane = planes[0];
		final rowBytes = (width + 7) >> 3;
		for (y in 0...height) {
			final rowOffset = y * rowBytes;
			for (x in 0...width) {
				final byte = plane.get(rowOffset + (x >> 3));
				final bit = (byte >> (7 - (x & 7))) & 0x1;
				final value = bit == 0 ? 255 : 0;
				writeRgba((y * width + x) * 4, value, value, value, 255);
			}
		}
	}

	function writeGrayscale(planes:Array<Bytes>, depth:Int):Void {
		final alphaPlane = planes.length > 1 ? planes[planes.length - 1] : null;
		for (y in 0...height) {
			for (x in 0...width) {
				final gray = readByteSample(planes[0], x, y, depth, width);
				final alpha = alphaPlane != null ? readByteSample(alphaPlane, x, y, depth, width) : 255;
				writeRgba((y * width + x) * 4, gray, gray, gray, alpha);
			}
		}
	}

	function writeIndexed(planes:Array<Bytes>, depth:Int, palette:Bytes):Void {
		if (palette == null)
			DecodeTools.fail("PSD indexed image is missing a palette");

		final alphaPlane = planes.length > 1 ? planes[planes.length - 1] : null;
		for (y in 0...height) {
			for (x in 0...width) {
				final index = readIntSample(planes[0], x, y, depth, width);
				if (index < 0 || index * 4 + 3 >= palette.length)
					DecodeTools.fail('PSD palette index out of range: $index');

				final dst = (y * width + x) * 4;
				pixels.set(dst + 0, palette.get(index * 4 + 0));
				pixels.set(dst + 1, palette.get(index * 4 + 1));
				pixels.set(dst + 2, palette.get(index * 4 + 2));
				pixels.set(dst + 3, alphaPlane != null ? readByteSample(alphaPlane, x, y, depth, width) : 255);
			}
		}
	}

	function writeRgb(planes:Array<Bytes>, depth:Int):Void {
		if (planes.length < 3)
			DecodeTools.fail("PSD RGB image is missing color channels");

		final alphaPlane = planes.length > 3 ? planes[planes.length - 1] : null;
		for (y in 0...height) {
			for (x in 0...width) {
				writeRgba((y * width + x) * 4, readByteSample(planes[0], x, y, depth, width), readByteSample(planes[1], x, y, depth, width),
					readByteSample(planes[2], x, y, depth, width), alphaPlane != null ? readByteSample(alphaPlane, x, y, depth, width) : 255);
			}
		}
	}

	function writeCmyk(planes:Array<Bytes>, depth:Int):Void {
		if (planes.length < 4)
			DecodeTools.fail("PSD CMYK image is missing color channels");

		final alphaPlane = planes.length > 4 ? planes[planes.length - 1] : null;
		for (y in 0...height) {
			for (x in 0...width) {
				final c = readUnitSample(planes[0], x, y, depth, width);
				final m = readUnitSample(planes[1], x, y, depth, width);
				final yv = readUnitSample(planes[2], x, y, depth, width);
				final k = readUnitSample(planes[3], x, y, depth, width);
				final r = DecodeTools.clampByte((1.0 - c) * (1.0 - k) * 255.0);
				final g = DecodeTools.clampByte((1.0 - m) * (1.0 - k) * 255.0);
				final b = DecodeTools.clampByte((1.0 - yv) * (1.0 - k) * 255.0);
				final a = alphaPlane != null ? readByteSample(alphaPlane, x, y, depth, width) : 255;
				writeRgba((y * width + x) * 4, r, g, b, a);
			}
		}
	}

	inline function writeRgba(offset:Int, r:Int, g:Int, b:Int, a:Int):Void {
		pixels.set(offset + 0, r);
		pixels.set(offset + 1, g);
		pixels.set(offset + 2, b);
		pixels.set(offset + 3, a);
	}

	function readIntSample(plane:Bytes, x:Int, y:Int, depth:Int, rowWidth:Int):Int {
		final rowBytes = ((rowWidth * depth) + 7) >> 3;
		final rowOffset = y * rowBytes;
		return switch depth {
			case 1:
				(plane.get(rowOffset + (x >> 3)) >> (7 - (x & 7))) & 0x1;
			case 8:
				plane.get(rowOffset + x);
			case 16:
				DecodeTools.u16BE(plane, rowOffset + x * 2);
			case 32:
				final value = DecodeTools.float32BE(plane, rowOffset + x * 4);
				value <= 0 ? 0 : Std.int(value);
			case _:
				DecodeTools.fail('Unsupported PSD bit depth: $depth');
		}
	}

	function readUnitSample(plane:Bytes, x:Int, y:Int, depth:Int, rowWidth:Int):Float {
		final rowBytes = ((rowWidth * depth) + 7) >> 3;
		final rowOffset = y * rowBytes;
		return switch depth {
			case 1:
				readIntSample(plane, x, y, depth, rowWidth) != 0 ? 1.0 : 0.0;
			case 8:
				plane.get(rowOffset + x) / 255.0;
			case 16:
				DecodeTools.u16BE(plane, rowOffset + x * 2) / 65535.0;
			case 32:
				final value = DecodeTools.float32BE(plane, rowOffset + x * 4);
				if (Math.isNaN(value) || value < 0) 0.0 else value;
			case _:
				DecodeTools.fail('Unsupported PSD bit depth: $depth');
		}
	}

	function readByteSample(plane:Bytes, x:Int, y:Int, depth:Int, rowWidth:Int):Int {
		return switch depth {
			case 1:
				readIntSample(plane, x, y, depth, rowWidth) == 0 ? 0 : 255;
			case 8:
				readIntSample(plane, x, y, depth, rowWidth);
			case 16:
				DecodeTools.scaleToByte(readIntSample(plane, x, y, depth, rowWidth), 16);
			case 32:
				final value = readUnitSample(plane, x, y, depth, rowWidth);
				value <= 1.0 ? DecodeTools.clampByte(value * 255.0) : DecodeTools.toneMap(value);
			case _:
				DecodeTools.fail('Unsupported PSD bit depth: $depth');
		}
	}

	function applyZipPrediction(plane:Bytes, rowBytes:Int, depth:Int):Void {
		final sampleBytes = switch depth {
			case 1, 8: 1;
			case 16: 2;
			case 32: 4;
			case _: DecodeTools.fail('Unsupported PSD ZIP prediction depth: $depth');
		}

		for (y in 0...height) {
			final rowOffset = y * rowBytes;
			for (i in sampleBytes...rowBytes)
				plane.set(rowOffset + i, (plane.get(rowOffset + i) + plane.get(rowOffset + i - sampleBytes)) & 0xff);
		}
	}
}
