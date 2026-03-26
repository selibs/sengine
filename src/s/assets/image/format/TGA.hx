package s.assets.image.format;

import haxe.io.Bytes;

/**
 * Decodes a subset of the TGA format into raw RGBA pixels for Kha.
 *
 * Supported image types:
 * - uncompressed color-mapped, true-color, grayscale
 * - RLE color-mapped, true-color, grayscale
 *
 * Supported pixel formats:
 * - indexed: 8/16-bit indices
 * - true-color: 15/16/24/32-bit
 * - grayscale: 8/16-bit
 */
class TGA extends ImageDecoder {
	static inline final headerSize:Int = 18;
	static inline final pixelStride:Int = 4;

	static function readImagePixel(bytes:Bytes, offset:Int, baseType:Int, pixelDepth:Int, alphaBits:Int, colorMap:Bytes, colorMapFirstIndex:Int,
			colorMapLength:Int, out:Bytes, outPos:Int):Int {
		return switch baseType {
			case 1: readColorMappedPixel(bytes, offset, pixelDepth, colorMap, colorMapFirstIndex, colorMapLength, out, outPos);
			case 2: readTrueColorPixel(bytes, offset, pixelDepth, alphaBits, out, outPos);
			case 3: readGrayPixel(bytes, offset, pixelDepth, out, outPos);
			case _: fail('Unsupported TGA base image type: $baseType');
		}
	}

	static function readColorMappedPixel(bytes:Bytes, offset:Int, pixelDepth:Int, colorMap:Bytes, colorMapFirstIndex:Int, colorMapLength:Int, out:Bytes,
			outPos:Int):Int {
		if (colorMap == null)
			return fail("TGA palette data is missing");

		final indexByteSize = switch pixelDepth {
			case 8, 16: byteSize(pixelDepth, "palette index size");
			case _: fail('Unsupported TGA palette index size: $pixelDepth');
		}

		ensureAvailable(bytes, offset, indexByteSize, "TGA palette index");

		var paletteIndex = 0;
		for (i in 0...indexByteSize)
			paletteIndex |= u8(bytes, offset + i) << (i * 8);

		final rawIndex = paletteIndex;
		paletteIndex -= colorMapFirstIndex;
		if (paletteIndex < 0 || paletteIndex >= colorMapLength)
			return fail('TGA palette index $rawIndex is out of range');

		out.blit(outPos, colorMap, paletteIndex * pixelStride, pixelStride);
		return offset + indexByteSize;
	}

	static function readTrueColorPixel(bytes:Bytes, offset:Int, pixelDepth:Int, alphaBits:Int, out:Bytes, outPos:Int):Int {
		return switch pixelDepth {
			case 15:
				ensureAvailable(bytes, offset, 2, "15-bit TGA pixel");
				write555(bytes, offset, false, out, outPos);
				offset + 2;
			case 16:
				ensureAvailable(bytes, offset, 2, "16-bit TGA pixel");
				write555(bytes, offset, alphaBits > 0, out, outPos);
				offset + 2;
			case 24:
				ensureAvailable(bytes, offset, 3, "24-bit TGA pixel");
				writeBgr(bytes, offset, out, outPos);
				offset + 3;
			case 32:
				ensureAvailable(bytes, offset, 4, "32-bit TGA pixel");
				writeBgra(bytes, offset, out, outPos);
				offset + 4;
			case _:
				fail('Unsupported TGA true-color pixel size: $pixelDepth');
		}
	}

	static function readGrayPixel(bytes:Bytes, offset:Int, pixelDepth:Int, out:Bytes, outPos:Int):Int {
		return switch pixelDepth {
			case 8:
				ensureAvailable(bytes, offset, 1, "8-bit grayscale TGA pixel");
				final value = u8(bytes, offset);
				out.set(outPos + 0, value);
				out.set(outPos + 1, value);
				out.set(outPos + 2, value);
				out.set(outPos + 3, 255);
				offset + 1;
			case 16:
				ensureAvailable(bytes, offset, 2, "16-bit grayscale TGA pixel");
				final value = u8(bytes, offset);
				out.set(outPos + 0, value);
				out.set(outPos + 1, value);
				out.set(outPos + 2, value);
				out.set(outPos + 3, u8(bytes, offset + 1));
				offset + 2;
			case _:
				fail('Unsupported TGA grayscale pixel size: $pixelDepth');
		}
	}

	static function readPaletteEntry(bytes:Bytes, offset:Int, entrySize:Int, out:Bytes, outPos:Int):Int {
		return switch entrySize {
			case 8:
				ensureAvailable(bytes, offset, 1, "8-bit TGA palette entry");
				final value = u8(bytes, offset);
				out.set(outPos + 0, value);
				out.set(outPos + 1, value);
				out.set(outPos + 2, value);
				out.set(outPos + 3, 255);
				offset + 1;
			case 15, 16:
				ensureAvailable(bytes, offset, 2, "16-bit TGA palette entry");
				write555(bytes, offset, false, out, outPos);
				offset + 2;
			case 24:
				ensureAvailable(bytes, offset, 3, "24-bit TGA palette entry");
				writeBgr(bytes, offset, out, outPos);
				offset + 3;
			case 32:
				ensureAvailable(bytes, offset, 4, "32-bit TGA palette entry");
				writeBgra(bytes, offset, out, outPos);
				offset + 4;
			case _:
				fail('Unsupported TGA palette entry size: $entrySize');
		}
	}

	static inline function writeBgr(bytes:Bytes, offset:Int, out:Bytes, outPos:Int) {
		out.set(outPos + 0, u8(bytes, offset + 2));
		out.set(outPos + 1, u8(bytes, offset + 1));
		out.set(outPos + 2, u8(bytes, offset + 0));
		out.set(outPos + 3, 255);
	}

	static inline function writeBgra(bytes:Bytes, offset:Int, out:Bytes, outPos:Int) {
		out.set(outPos + 0, u8(bytes, offset + 2));
		out.set(outPos + 1, u8(bytes, offset + 1));
		out.set(outPos + 2, u8(bytes, offset + 0));
		out.set(outPos + 3, u8(bytes, offset + 3));
	}

	static inline function write555(bytes:Bytes, offset:Int, useAlpha:Bool, out:Bytes, outPos:Int) {
		final value = u16(bytes, offset);
		out.set(outPos + 0, expand5((value >> 10) & 0x1f));
		out.set(outPos + 1, expand5((value >> 5) & 0x1f));
		out.set(outPos + 2, expand5(value & 0x1f));
		out.set(outPos + 3, useAlpha ? ((value & 0x8000) != 0 ? 255 : 0) : 255);
	}

	static inline function expand5(value:Int):Int
		return (value << 3) | (value >> 2);

	static inline function outputOffset(index:Int, width:Int, height:Int, topToBottom:Bool, rightToLeft:Bool):Int {
		final x = index % width;
		final y = Std.int(index / width);
		final imageX = rightToLeft ? width - 1 - x : x;
		final imageY = topToBottom ? y : height - 1 - y;
		return (imageY * width + imageX) * pixelStride;
	}

	static inline function byteSize(bits:Int, label:String):Int {
		if (bits <= 0)
			return fail('Invalid TGA $label: $bits');
		return (bits + 7) >> 3;
	}

	static inline function u8(bytes:Bytes, offset:Int):Int
		return bytes.get(offset);

	static inline function u16(bytes:Bytes, offset:Int):Int
		return u8(bytes, offset) | (u8(bytes, offset + 1) << 8);

	static inline function ensureAvailable(bytes:Bytes, offset:Int, size:Int, what:String)
		if (size < 0 || offset < 0 || offset > bytes.length - size)
			fail('Unexpected end of TGA while reading $what');

	static inline function fail<T>(message:String):T
		throw new haxe.Exception(message);

	public function decode(bytes:Bytes):Void {
		ensureAvailable(bytes, 0, headerSize, "TGA header");

		final idLength = u8(bytes, 0);
		final colorMapType = u8(bytes, 1);
		final imageType = u8(bytes, 2);
		final colorMapFirstIndex = u16(bytes, 3);
		final colorMapLength = u16(bytes, 5);
		final colorMapEntrySize = u8(bytes, 7);
		width = u16(bytes, 12);
		height = u16(bytes, 14);
		final pixelDepth = u8(bytes, 16);
		final descriptor = u8(bytes, 17);

		final topToBottom = (descriptor & 0x20) != 0;
		final rightToLeft = (descriptor & 0x10) != 0;
		final alphaBits = descriptor & 0x0f;
		final interleaveMode = descriptor & 0xc0;
		final baseType = imageType & 0x07;
		final isRle = (imageType & 0x08) != 0;

		if (width <= 0 || height <= 0)
			return fail('Invalid TGA size: ${width}x$height');

		if (interleaveMode != 0)
			return fail("Interleaved TGA images are not supported");

		if (imageType != 1 && imageType != 2 && imageType != 3 && imageType != 9 && imageType != 10 && imageType != 11)
			return fail('Unsupported TGA image type: $imageType');

		if (colorMapType != 0 && colorMapType != 1)
			return fail('Unsupported TGA color map type: $colorMapType');

		if (baseType == 1 && colorMapType != 1)
			return fail("Color-mapped TGA is missing a palette");

		var offset = headerSize;
		ensureAvailable(bytes, offset, idLength, "TGA image ID");
		offset += idLength;

		var colorMap:Bytes = null;
		if (colorMapType == 1) {
			if (colorMapLength <= 0)
				return fail("TGA palette is empty");

			final entryByteSize = byteSize(colorMapEntrySize, "palette entry size");
			ensureAvailable(bytes, offset, colorMapLength * entryByteSize, "TGA palette");

			colorMap = Bytes.alloc(colorMapLength * pixelStride);
			for (i in 0...colorMapLength) {
				offset = readPaletteEntry(bytes, offset, colorMapEntrySize, colorMap, i * pixelStride);
			}
		}

		final pixelCount = width * height;
		pixels = Bytes.alloc(pixelCount * pixelStride);

		if (!isRle) {
			for (i in 0...pixelCount) {
				final outPos = outputOffset(i, width, height, topToBottom, rightToLeft);
				offset = readImagePixel(bytes, offset, baseType, pixelDepth, alphaBits, colorMap, colorMapFirstIndex, colorMapLength, pixels, outPos);
			}
		} else {
			final scratch = Bytes.alloc(pixelStride);
			var decodedPixels = 0;
			while (decodedPixels < pixelCount) {
				ensureAvailable(bytes, offset, 1, "TGA RLE packet header");
				final packetHeader = u8(bytes, offset++);
				final packetLength = (packetHeader & 0x7f) + 1;

				if (decodedPixels + packetLength > pixelCount)
					return fail("TGA RLE packet overruns image bounds");

				if ((packetHeader & 0x80) != 0) {
					offset = readImagePixel(bytes, offset, baseType, pixelDepth, alphaBits, colorMap, colorMapFirstIndex, colorMapLength, scratch, 0);
					for (i in 0...packetLength) {
						final outPos = outputOffset(decodedPixels + i, width, height, topToBottom, rightToLeft);
						pixels.blit(outPos, scratch, 0, pixelStride);
					}
				} else {
					for (i in 0...packetLength) {
						final outPos = outputOffset(decodedPixels + i, width, height, topToBottom, rightToLeft);
						offset = readImagePixel(bytes, offset, baseType, pixelDepth, alphaBits, colorMap, colorMapFirstIndex, colorMapLength, pixels, outPos);
					}
				}

				decodedPixels += packetLength;
			}
		}

		finish();
	}
}
