package s.assets.image.format;

import haxe.io.Bytes;

class BMP extends ImageDecoder {
	static inline final fileHeaderSize:Int = 14;
	static inline final biRgb:Int = 0;
	static inline final biRle8:Int = 1;
	static inline final biRle4:Int = 2;
	static inline final biBitfields:Int = 3;
	static inline final biAlphaBitfields:Int = 6;

	public function decode(bytes:Bytes):Void {
		DecodeTools.ensureAvailable(bytes, 0, fileHeaderSize, "BMP header");
		if (DecodeTools.readTag(bytes, 0, 2) != "BM")
			DecodeTools.fail("Invalid BMP signature");

		final dataOffset = DecodeTools.u32LE(bytes, 10);
		final dibSize = DecodeTools.u32LE(bytes, 14);

		var bitCount:Int;
		var compression:Int = biRgb;
		var topDown = false;
		var paletteOffset = 14 + dibSize;
		var paletteEntrySize = 4;
		var colorsUsed = 0;
		var redMask = 0;
		var greenMask = 0;
		var blueMask = 0;
		var alphaMask = 0;

		if (dibSize == 12) {
			DecodeTools.ensureAvailable(bytes, 14, 12, "BMP core header");
			width = DecodeTools.u16LE(bytes, 18);
			height = DecodeTools.u16LE(bytes, 20);
			bitCount = DecodeTools.u16LE(bytes, 24);
			paletteEntrySize = 3;
		} else if (dibSize >= 40) {
			DecodeTools.ensureAvailable(bytes, 14, dibSize, "BMP info header");
			width = DecodeTools.i32LE(bytes, 18);
			var rawHeight = DecodeTools.i32LE(bytes, 22);
			topDown = rawHeight < 0;
			height = rawHeight < 0 ? -rawHeight : rawHeight;
			bitCount = DecodeTools.u16LE(bytes, 28);
			compression = DecodeTools.u32LE(bytes, 30);
			colorsUsed = DecodeTools.u32LE(bytes, 46);

			if (compression == biBitfields || compression == biAlphaBitfields) {
				final maskOffset = 14 + 40;
				DecodeTools.ensureAvailable(bytes, maskOffset, dibSize >= 56
					|| compression == biAlphaBitfields ? 16 : 12, "BMP channel masks");
				redMask = DecodeTools.u32LE(bytes, maskOffset);
				greenMask = DecodeTools.u32LE(bytes, maskOffset + 4);
				blueMask = DecodeTools.u32LE(bytes, maskOffset + 8);
				alphaMask = dibSize >= 56 || compression == biAlphaBitfields ? DecodeTools.u32LE(bytes, maskOffset + 12) : 0;
			}
		} else {
			DecodeTools.fail('Unsupported BMP DIB header size: $dibSize');
		}

		if (width <= 0 || height <= 0)
			DecodeTools.fail('Invalid BMP size: ${width}x$height');

		pixels = Bytes.alloc(width * height * 4);

		switch compression {
			case biRgb:
				decodeRaw(bytes, dataOffset, bitCount, paletteOffset, paletteEntrySize, colorsUsed, topDown, redMask, greenMask, blueMask, alphaMask);
			case biBitfields, biAlphaBitfields:
				decodeRaw(bytes, dataOffset, bitCount, paletteOffset, paletteEntrySize, colorsUsed, topDown, redMask, greenMask, blueMask, alphaMask);
			case biRle8:
				decodeRle(bytes, dataOffset, 8, paletteOffset, paletteEntrySize, colorsUsed, topDown);
			case biRle4:
				decodeRle(bytes, dataOffset, 4, paletteOffset, paletteEntrySize, colorsUsed, topDown);
			case _:
				DecodeTools.fail('Unsupported BMP compression: $compression');
		}

		finish();
	}

	function decodeRaw(bytes:Bytes, dataOffset:Int, bitCount:Int, paletteOffset:Int, paletteEntrySize:Int, colorsUsed:Int, topDown:Bool, redMask:Int,
			greenMask:Int, blueMask:Int, alphaMask:Int):Void {
		final palette = bitCount <= 8 ? readPalette(bytes, paletteOffset, paletteEntrySize, colorsUsed, 1 << bitCount) : null;
		final rowStride = ((width * bitCount + 31) >> 5) << 2;
		DecodeTools.ensureAvailable(bytes, dataOffset, rowStride * height, "BMP pixel data");

		var sawAlpha = false;
		for (row in 0...height) {
			final srcRow = dataOffset + row * rowStride;
			final y = topDown ? row : height - 1 - row;
			final dstRow = y * width * 4;
			switch bitCount {
				case 1:
					for (x in 0...width)
						writePalettePixel(palette, DecodeTools.unpackBitsAt(bytes, srcRow, 1, x), dstRow + x * 4);
				case 4:
					for (x in 0...width)
						writePalettePixel(palette, DecodeTools.unpackBitsAt(bytes, srcRow, 4, x), dstRow + x * 4);
				case 8:
					for (x in 0...width)
						writePalettePixel(palette, bytes.get(srcRow + x), dstRow + x * 4);
				case 16:
					final useMasks = redMask != 0 || greenMask != 0 || blueMask != 0;
					final rm = useMasks ? redMask : 0x7c00;
					final gm = useMasks ? greenMask : 0x03e0;
					final bm = useMasks ? blueMask : 0x001f;
					final am = useMasks ? alphaMask : 0;
					for (x in 0...width) {
						final value = DecodeTools.u16LE(bytes, srcRow + x * 2);
						final dst = dstRow + x * 4;
						pixels.set(dst + 0, DecodeTools.extractMasked(value, rm));
						pixels.set(dst + 1, DecodeTools.extractMasked(value, gm));
						pixels.set(dst + 2, DecodeTools.extractMasked(value, bm));
						final alpha = am != 0 ? DecodeTools.extractMasked(value, am) : 255;
						pixels.set(dst + 3, alpha);
						sawAlpha = sawAlpha || alpha != 0;
					}
				case 24:
					for (x in 0...width) {
						final src = srcRow + x * 3;
						final dst = dstRow + x * 4;
						pixels.set(dst + 0, bytes.get(src + 2));
						pixels.set(dst + 1, bytes.get(src + 1));
						pixels.set(dst + 2, bytes.get(src + 0));
						pixels.set(dst + 3, 255);
					}
				case 32:
					final rm = redMask != 0 ? redMask : 0x00ff0000;
					final gm = greenMask != 0 ? greenMask : 0x0000ff00;
					final bm = blueMask != 0 ? blueMask : 0x000000ff;
					final am = alphaMask != 0 ? alphaMask : 0xff000000;
					for (x in 0...width) {
						final value = DecodeTools.u32LE(bytes, srcRow + x * 4);
						final dst = dstRow + x * 4;
						pixels.set(dst + 0, DecodeTools.extractMasked(value, rm));
						pixels.set(dst + 1, DecodeTools.extractMasked(value, gm));
						pixels.set(dst + 2, DecodeTools.extractMasked(value, bm));
						final alpha = alphaMask != 0 ? DecodeTools.extractMasked(value, am) : bytes.get(srcRow + x * 4 + 3);
						pixels.set(dst + 3, alpha);
						sawAlpha = sawAlpha || alpha != 0;
					}
				case _:
					DecodeTools.fail('Unsupported BMP bit depth: $bitCount');
			}
		}

		if (bitCount == 32 && alphaMask == 0 && !sawAlpha) {
			for (i in 0...width * height)
				pixels.set(i * 4 + 3, 255);
		}
	}

	function decodeRle(bytes:Bytes, dataOffset:Int, bitCount:Int, paletteOffset:Int, paletteEntrySize:Int, colorsUsed:Int, topDown:Bool):Void {
		final palette = readPalette(bytes, paletteOffset, paletteEntrySize, colorsUsed, 1 << bitCount);
		var x = 0;
		var y = topDown ? 0 : height - 1;
		var offset = dataOffset;

		while (offset < bytes.length) {
			DecodeTools.ensureAvailable(bytes, offset, 2, "BMP RLE packet");
			final count = bytes.get(offset++);
			final value = bytes.get(offset++);

			if (count > 0) {
				if (bitCount == 8) {
					for (i in 0...count)
						writePalettePixelAt(palette, value, x++, y);
				} else {
					final hi = (value >> 4) & 0xf;
					final lo = value & 0xf;
					for (i in 0...count) {
						writePalettePixelAt(palette, (i & 1) == 0 ? hi : lo, x++, y);
					}
				}
				continue;
			}

			switch value {
				case 0:
					x = 0;
					y += topDown ? 1 : -1;
				case 1:
					return;
				case 2:
					DecodeTools.ensureAvailable(bytes, offset, 2, "BMP RLE delta");
					x += bytes.get(offset++);
					y += (topDown ? 1 : -1) * bytes.get(offset++);
				case _:
					final absoluteCount = value;
					if (bitCount == 8) {
						DecodeTools.ensureAvailable(bytes, offset, absoluteCount + (absoluteCount & 1), "BMP RLE absolute run");
						for (i in 0...absoluteCount)
							writePalettePixelAt(palette, bytes.get(offset + i), x++, y);
						offset += absoluteCount;
						if ((absoluteCount & 1) != 0)
							offset++;
					} else {
						final byteCount = (absoluteCount + 1) >> 1;
						DecodeTools.ensureAvailable(bytes, offset, byteCount + (byteCount & 1), "BMP RLE absolute nibble run");
						for (i in 0...absoluteCount) {
							final b = bytes.get(offset + (i >> 1));
							final index = (i & 1) == 0 ? (b >> 4) & 0xf : b & 0xf;
							writePalettePixelAt(palette, index, x++, y);
						}
						offset += byteCount;
						if ((byteCount & 1) != 0)
							offset++;
					}
			}
		}
	}

	function readPalette(bytes:Bytes, offset:Int, entrySize:Int, colorsUsed:Int, fallbackCount:Int):Array<Int> {
		final count = colorsUsed > 0 ? colorsUsed : fallbackCount;
		DecodeTools.ensureAvailable(bytes, offset, count * entrySize, "BMP palette");
		final palette = new Array<Int>();
		for (i in 0...count) {
			final base = offset + i * entrySize;
			final b = bytes.get(base);
			final g = bytes.get(base + 1);
			final r = bytes.get(base + 2);
			palette.push((r << 16) | (g << 8) | b);
		}
		return palette;
	}

	inline function writePalettePixel(palette:Array<Int>, index:Int, dst:Int):Void {
		if (index < 0 || index >= palette.length)
			DecodeTools.fail('BMP palette index out of range: $index');
		final color = palette[index];
		pixels.set(dst + 0, (color >> 16) & 0xff);
		pixels.set(dst + 1, (color >> 8) & 0xff);
		pixels.set(dst + 2, color & 0xff);
		pixels.set(dst + 3, 255);
	}

	inline function writePalettePixelAt(palette:Array<Int>, index:Int, x:Int, y:Int):Void {
		if (x < 0 || x >= width || y < 0 || y >= height)
			DecodeTools.fail("BMP RLE pixel is outside image bounds");
		writePalettePixel(palette, index, (y * width + x) * 4);
	}
}
