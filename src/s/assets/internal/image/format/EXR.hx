package s.assets.internal.image.format;

import haxe.io.Bytes;

private typedef ExrChannel = {
	var name:String;
	var pixelType:Int;
	var xSampling:Int;
	var ySampling:Int;
}

class EXR extends ImageDecoder {
	static inline final compressionNone:Int = 0;
	static inline final compressionZips:Int = 2;
	static inline final compressionZip:Int = 3;

	static inline final pixelTypeUInt:Int = 0;
	static inline final pixelTypeHalf:Int = 1;
	static inline final pixelTypeFloat:Int = 2;

	public function decode(bytes:Bytes):Void {
		DecodeTools.ensureAvailable(bytes, 0, 8, "EXR header");
		if (DecodeTools.u32LE(bytes, 0) != 20000630)
			DecodeTools.fail("Invalid EXR signature");

		final versionField = DecodeTools.u32LE(bytes, 4);
		final version = versionField & 0xff;
		final flags = versionField & ~0xff;
		if (version != 2)
			DecodeTools.fail('Unsupported EXR version: $version');
		if (flags != 0)
			DecodeTools.fail("Multipart, tiled, deep, and long-name EXR files are not supported");

		var offset = 8;
		var channels:Array<ExrChannel> = null;
		var compression = compressionNone;
		var minX = 0;
		var minY = 0;
		var maxX = -1;
		var maxY = -1;

		while (true) {
			final nameInfo = DecodeTools.readCString(bytes, offset, bytes.length);
			offset = nameInfo.next;
			if (nameInfo.value.length == 0)
				break;

			final typeInfo = DecodeTools.readCString(bytes, offset, bytes.length);
			offset = typeInfo.next;
			DecodeTools.ensureAvailable(bytes, offset, 4, 'EXR attribute "${nameInfo.value}" size');
			final size = DecodeTools.u32LE(bytes, offset);
			offset += 4;
			DecodeTools.ensureAvailable(bytes, offset, size, 'EXR attribute "${nameInfo.value}" payload');

			switch nameInfo.value {
				case "channels":
					channels = readChannels(bytes, offset, size);
				case "compression":
					if (size < 1)
						DecodeTools.fail("Invalid EXR compression attribute");
					compression = bytes.get(offset);
				case "dataWindow":
					if (size != 16)
						DecodeTools.fail("Invalid EXR dataWindow attribute");
					minX = DecodeTools.i32LE(bytes, offset);
					minY = DecodeTools.i32LE(bytes, offset + 4);
					maxX = DecodeTools.i32LE(bytes, offset + 8);
					maxY = DecodeTools.i32LE(bytes, offset + 12);
				case _:
			}

			offset += size;
		}

		if (channels == null || channels.length == 0)
			DecodeTools.fail("EXR image is missing channels");
		if (maxX < minX || maxY < minY)
			DecodeTools.fail("Invalid EXR dataWindow");

		for (channel in channels) {
			if (channel.xSampling != 1 || channel.ySampling != 1)
				DecodeTools.fail('Unsupported EXR channel sampling for "${channel.name}"');
		}

		if (compression != compressionNone && compression != compressionZips && compression != compressionZip)
			DecodeTools.fail('Unsupported EXR compression: $compression');

		width = maxX - minX + 1;
		height = maxY - minY + 1;
		pixels = Bytes.alloc(width * height * 4);

		final linesPerBlock = compression == compressionZip ? 16 : 1;
		final blockCount = Std.int((height + linesPerBlock - 1) / linesPerBlock);
		DecodeTools.ensureAvailable(bytes, offset, blockCount * 8, "EXR line offset table");
		final lineOffsetTable = offset;
		offset += blockCount * 8;

		final indexR = findChannel(channels, "R");
		final indexG = findChannel(channels, "G");
		final indexB = findChannel(channels, "B");
		final indexA = findChannel(channels, "A");
		final indexY = findChannel(channels, "Y");
		if (indexY < 0 && (indexR < 0 || indexG < 0 || indexB < 0))
			DecodeTools.fail("EXR image must contain either RGB or Y channels");

		for (block in 0...blockCount) {
			final chunkOffset = readOffset64(bytes, lineOffsetTable + block * 8);
			DecodeTools.ensureAvailable(bytes, chunkOffset, 8, "EXR chunk header");
			final yCoordinate = DecodeTools.i32LE(bytes, chunkOffset);
			final packedSize = DecodeTools.u32LE(bytes, chunkOffset + 4);
			final dataOffset = chunkOffset + 8;
			DecodeTools.ensureAvailable(bytes, dataOffset, packedSize, "EXR chunk data");

			final localY = yCoordinate - minY;
			if (localY < 0 || localY >= height)
				DecodeTools.fail('EXR chunk starts outside dataWindow: $yCoordinate');

			final linesInBlock = Std.int(Math.min(linesPerBlock, height - localY));
			final expectedSize = expectedBlockSize(channels, linesInBlock);
			final blockBytes = decodeBlock(bytes.sub(dataOffset, packedSize), compression, expectedSize);
			writeBlock(blockBytes, channels, localY, linesInBlock, indexR, indexG, indexB, indexA, indexY);
		}

		finish();
	}

	function readChannels(bytes:Bytes, offset:Int, length:Int):Array<ExrChannel> {
		final end = offset + length;
		final channels = new Array<ExrChannel>();
		var pos = offset;

		while (pos < end) {
			final nameInfo = DecodeTools.readCString(bytes, pos, end);
			pos = nameInfo.next;
			if (nameInfo.value.length == 0)
				break;

			DecodeTools.ensureAvailable(bytes, pos, 16, 'EXR channel "${nameInfo.value}"');
			final pixelType = DecodeTools.i32LE(bytes, pos);
			final xSampling = DecodeTools.i32LE(bytes, pos + 8);
			final ySampling = DecodeTools.i32LE(bytes, pos + 12);
			pos += 16;

			if (pixelType != pixelTypeUInt && pixelType != pixelTypeHalf && pixelType != pixelTypeFloat)
				DecodeTools.fail('Unsupported EXR pixel type: $pixelType');

			channels.push({
				name: nameInfo.value.toUpperCase(),
				pixelType: pixelType,
				xSampling: xSampling,
				ySampling: ySampling
			});
		}

		return channels;
	}

	function decodeBlock(data:Bytes, compression:Int, expectedLength:Int):Bytes {
		return switch compression {
			case compressionNone:
				if (data.length < expectedLength)
					DecodeTools.fail("EXR chunk is shorter than expected");
				final out = Bytes.alloc(expectedLength);
				out.blit(0, data, 0, expectedLength);
				out;
			case compressionZips, compressionZip:
				final inflated = DecodeTools.inflate(data);
				if (inflated.length < expectedLength)
					DecodeTools.fail("EXR ZIP chunk is shorter than expected");
				restoreZipBlock(inflated, expectedLength);
			case _:
				DecodeTools.fail('Unsupported EXR compression: $compression');
		}
	}

	function restoreZipBlock(data:Bytes, expectedLength:Int):Bytes {
		final predicted = Bytes.alloc(expectedLength);
		predicted.set(0, data.get(0));
		for (i in 1...expectedLength)
			predicted.set(i, (predicted.get(i - 1) + data.get(i) - 128) & 0xff);

		final out = Bytes.alloc(expectedLength);
		final half = (expectedLength + 1) >> 1;
		for (i in 0...half) {
			final dst = i << 1;
			out.set(dst, predicted.get(i));
			if (dst + 1 < expectedLength)
				out.set(dst + 1, predicted.get(i + half));
		}
		return out;
	}

	function writeBlock(blockBytes:Bytes, channels:Array<ExrChannel>, startY:Int, lines:Int, indexR:Int, indexG:Int, indexB:Int, indexA:Int, indexY:Int):Void {
		final channelOffsets = new Array<Int>();
		var offset = 0;
		for (channel in channels) {
			channelOffsets.push(offset);
			offset += width * lines * channelByteSize(channel.pixelType);
		}
		if (offset > blockBytes.length)
			DecodeTools.fail("EXR block data is truncated");

		for (localY in 0...lines) {
			final y = startY + localY;
			for (x in 0...width) {
				final luminance = indexY >= 0 ? readChannelValue(blockBytes, channelOffsets[indexY], channels[indexY], localY, x) : null;
				final rValue = indexR >= 0 ? readChannelValue(blockBytes, channelOffsets[indexR], channels[indexR], localY, x) : luminance;
				final gValue = indexG >= 0 ? readChannelValue(blockBytes, channelOffsets[indexG], channels[indexG], localY, x) : luminance;
				final bValue = indexB >= 0 ? readChannelValue(blockBytes, channelOffsets[indexB], channels[indexB], localY, x) : luminance;
				final aValue = indexA >= 0 ? readChannelValue(blockBytes, channelOffsets[indexA], channels[indexA], localY, x) : null;
				final dst = (y * width + x) * 4;

				pixels.set(dst + 0, colorToByte(rValue, indexR >= 0 ? channels[indexR].pixelType : channels[indexY].pixelType));
				pixels.set(dst + 1, colorToByte(gValue, indexG >= 0 ? channels[indexG].pixelType : channels[indexY].pixelType));
				pixels.set(dst + 2, colorToByte(bValue, indexB >= 0 ? channels[indexB].pixelType : channels[indexY].pixelType));
				pixels.set(dst + 3, aValue == null ? 255 : alphaToByte(aValue, channels[indexA].pixelType));
			}
		}
	}

	function readChannelValue(bytes:Bytes, channelOffset:Int, channel:ExrChannel, y:Int, x:Int):Float {
		final stride = channelByteSize(channel.pixelType);
		final offset = channelOffset + (y * width + x) * stride;
		return switch channel.pixelType {
			case pixelTypeUInt:
				final value = DecodeTools.u32LE(bytes, offset);
				value < 0 ? value + 4294967296.0 : value;
			case pixelTypeHalf:
				DecodeTools.halfToFloat(DecodeTools.u16LE(bytes, offset));
			case pixelTypeFloat:
				DecodeTools.float32LE(bytes, offset);
			case _:
				DecodeTools.fail('Unsupported EXR pixel type: ${channel.pixelType}');
		}
	}

	function colorToByte(value:Null<Float>, pixelType:Int):Int {
		if (value == null || Math.isNaN(value) || value <= 0)
			return 0;
		return switch pixelType {
			case pixelTypeUInt:
				value <= 255.0 ? DecodeTools.clampByte(value) : DecodeTools.toneMap(value / 255.0);
			case _:
				value <= 1.0 ? DecodeTools.clampByte(value * 255.0) : DecodeTools.toneMap(value);
		}
	}

	function alphaToByte(value:Float, pixelType:Int):Int {
		if (Math.isNaN(value) || value <= 0)
			return 0;
		return switch pixelType {
			case pixelTypeUInt:
				DecodeTools.clampByte(value);
			case _:
				DecodeTools.clampByte(value * 255.0);
		}
	}

	inline function expectedBlockSize(channels:Array<ExrChannel>, lines:Int):Int {
		var total = 0;
		for (channel in channels)
			total += width * lines * channelByteSize(channel.pixelType);
		return total;
	}

	inline function channelByteSize(pixelType:Int):Int {
		return switch pixelType {
			case pixelTypeUInt, pixelTypeFloat: 4;
			case pixelTypeHalf: 2;
			case _: DecodeTools.fail('Unsupported EXR pixel type: $pixelType');
		}
	}

	function findChannel(channels:Array<ExrChannel>, name:String):Int {
		final target = name.toUpperCase();
		for (i in 0...channels.length) {
			if (channels[i].name == target)
				return i;
		}
		return -1;
	}

	function readOffset64(bytes:Bytes, offset:Int):Int {
		DecodeTools.ensureAvailable(bytes, offset, 8, "EXR chunk offset");
		final low = DecodeTools.u32LE(bytes, offset);
		final high = DecodeTools.u32LE(bytes, offset + 4);
		if (high != 0)
			DecodeTools.fail("Large EXR chunk offsets are not supported");
		return low;
	}
}
