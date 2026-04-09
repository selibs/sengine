package s.assets.internal.image.format;

import haxe.io.Bytes;

class PNG extends ImageDecoder {
	static final signature = Bytes.ofHex("89504e470d0a1a0a");
	static final interlacePasses = [
		{
			x: 0,
			y: 0,
			dx: 8,
			dy: 8
		},
		{
			x: 4,
			y: 0,
			dx: 8,
			dy: 8
		},
		{
			x: 0,
			y: 4,
			dx: 4,
			dy: 8
		},
		{
			x: 2,
			y: 0,
			dx: 4,
			dy: 4
		},
		{
			x: 0,
			y: 2,
			dx: 2,
			dy: 4
		},
		{
			x: 1,
			y: 0,
			dx: 2,
			dy: 2
		},
		{
			x: 0,
			y: 1,
			dx: 1,
			dy: 2
		}
	];

	public function decode(bytes:Bytes):Void {
		DecodeTools.ensureAvailable(bytes, 0, signature.length, "PNG signature");
		if (bytes.sub(0, signature.length).compare(signature) != 0)
			DecodeTools.fail("Invalid PNG signature");

		var bitDepth = 0;
		var colorType = -1;
		var interlaceMethod = 0;
		var palette:Bytes = null;
		var paletteAlpha:Bytes = null;
		var transparentGray:Int = -1;
		var transparentRgb:Array<Int> = null;
		var idat = new Array<Bytes>();

		var offset = signature.length;
		while (offset < bytes.length) {
			DecodeTools.ensureAvailable(bytes, offset, 12, "PNG chunk");
			final length = DecodeTools.u32BE(bytes, offset);
			final type = DecodeTools.readTag(bytes, offset + 4, 4);
			final dataOffset = offset + 8;
			DecodeTools.ensureAvailable(bytes, dataOffset, length, 'PNG chunk "$type"');

			switch type {
				case "IHDR":
					if (length != 13)
						DecodeTools.fail("Invalid IHDR chunk length");
					width = DecodeTools.u32BE(bytes, dataOffset);
					height = DecodeTools.u32BE(bytes, dataOffset + 4);
					bitDepth = bytes.get(dataOffset + 8);
					colorType = bytes.get(dataOffset + 9);
					final compressionMethod = bytes.get(dataOffset + 10);
					final filterMethod = bytes.get(dataOffset + 11);
					interlaceMethod = bytes.get(dataOffset + 12);

					if (width <= 0 || height <= 0)
						DecodeTools.fail('Invalid PNG size: ${width}x$height');
					if (compressionMethod != 0 || filterMethod != 0)
						DecodeTools.fail("Unsupported PNG compression or filter method");
					if (interlaceMethod != 0 && interlaceMethod != 1)
						DecodeTools.fail('Unsupported PNG interlace method: $interlaceMethod');
				case "PLTE":
					palette = bytes.sub(dataOffset, length);
				case "tRNS":
					switch colorType {
						case 0:
							if (length >= 2) transparentGray = DecodeTools.u16BE(bytes, dataOffset);
						case 2:
							if (length >= 6) transparentRgb = [
								DecodeTools.u16BE(bytes, dataOffset),
								DecodeTools.u16BE(bytes, dataOffset + 2),
								DecodeTools.u16BE(bytes, dataOffset + 4)
							];
						case 3:
							paletteAlpha = bytes.sub(dataOffset, length);
						case _:
					}
				case "IDAT":
					idat.push(bytes.sub(dataOffset, length));
				case "IEND":
					break;
				case _:
			}

			offset = dataOffset + length + 4;
			if (type == "IEND")
				break;
		}

		if (colorType == -1)
			DecodeTools.fail("PNG image is missing IHDR");
		if (idat.length == 0)
			DecodeTools.fail("PNG image is missing IDAT");
		if (colorType == 3 && palette == null)
			DecodeTools.fail("Indexed PNG image is missing a palette");
		if (palette != null && (palette.length % 3) != 0)
			DecodeTools.fail("PNG palette chunk has invalid size");

		switch colorType {
			case 0:
				if (bitDepth != 1 && bitDepth != 2 && bitDepth != 4 && bitDepth != 8 && bitDepth != 16)
					DecodeTools.fail('Unsupported PNG grayscale bit depth: $bitDepth');
			case 2:
				if (bitDepth != 8 && bitDepth != 16)
					DecodeTools.fail('Unsupported PNG RGB bit depth: $bitDepth');
			case 3:
				if (bitDepth != 1 && bitDepth != 2 && bitDepth != 4 && bitDepth != 8)
					DecodeTools.fail('Unsupported PNG indexed bit depth: $bitDepth');
			case 4:
				if (bitDepth != 8 && bitDepth != 16)
					DecodeTools.fail('Unsupported PNG grayscale+alpha bit depth: $bitDepth');
			case 6:
				if (bitDepth != 8 && bitDepth != 16)
					DecodeTools.fail('Unsupported PNG RGBA bit depth: $bitDepth');
			case _:
				DecodeTools.fail('Unsupported PNG color type: $colorType');
		}

		final channels = switch colorType {
			case 0: 1;
			case 2: 3;
			case 3: 1;
			case 4: 2;
			case 6: 4;
			case _: 0;
		}

		final decoded = DecodeTools.inflate(DecodeTools.concat(idat));
		pixels = Bytes.alloc(width * height * 4);

		var src = 0;
		final passes:Array<{
			x:Int,
			y:Int,
			dx:Int,
			dy:Int
		}> = interlaceMethod == 0 ? [
			{
				x: 0,
				y: 0,
				dx: 1,
				dy: 1
			}
		] : interlacePasses;

		for (pass in passes) {
			final passWidth = reducedSize(width, pass.x, pass.dx);
			final passHeight = reducedSize(height, pass.y, pass.dy);
			if (passWidth <= 0 || passHeight <= 0)
				continue;

			final packedBytesPerPixel = Std.int(Math.max(1.0, Math.ceil((channels * bitDepth) / 8.0)));
			final scanlineBytes = ((passWidth * channels * bitDepth) + 7) >> 3;
			final previous = Bytes.alloc(scanlineBytes);
			final current = Bytes.alloc(scanlineBytes);

			for (passY in 0...passHeight) {
				DecodeTools.ensureAvailable(decoded, src, scanlineBytes + 1, "PNG scanline data");
				final filter = decoded.get(src++);
				current.blit(0, decoded, src, scanlineBytes);
				src += scanlineBytes;
				unfilter(current, previous, filter, packedBytesPerPixel);
				writeScanline(current, pass.x, pass.y, pass.dx, pass.dy, passY, passWidth, bitDepth, colorType, channels, palette, paletteAlpha,
					transparentGray, transparentRgb);
				previous.blit(0, current, 0, scanlineBytes);
			}
		}

		finish();
	}

	function unfilter(current:Bytes, previous:Bytes, filter:Int, bpp:Int):Void {
		switch filter {
			case 0:
			case 1:
				for (i in bpp...current.length)
					current.set(i, (current.get(i) + current.get(i - bpp)) & 0xff);
			case 2:
				for (i in 0...current.length)
					current.set(i, (current.get(i) + previous.get(i)) & 0xff);
			case 3:
				for (i in 0...current.length) {
					final left = i >= bpp ? current.get(i - bpp) : 0;
					final up = previous.get(i);
					current.set(i, (current.get(i) + ((left + up) >> 1)) & 0xff);
				}
			case 4:
				for (i in 0...current.length) {
					final left = i >= bpp ? current.get(i - bpp) : 0;
					final up = previous.get(i);
					final upLeft = i >= bpp ? previous.get(i - bpp) : 0;
					current.set(i, (current.get(i) + DecodeTools.paeth(left, up, upLeft)) & 0xff);
				}
			case _:
				DecodeTools.fail('Unsupported PNG filter: $filter');
		}
	}

	function writeScanline(line:Bytes, startX:Int, startY:Int, stepX:Int, stepY:Int, row:Int, rowWidth:Int, bitDepth:Int, colorType:Int, channels:Int,
			palette:Bytes, paletteAlpha:Bytes, transparentGray:Int, transparentRgb:Array<Int>):Void {
		final y = startY + row * stepY;
		for (x in 0...rowWidth) {
			final imageX = startX + x * stepX;
			final dst = (y * width + imageX) * 4;

			switch colorType {
				case 0:
					final sample = readSample(line, bitDepth, x, 1, 0);
					final gray = sampleToByte(sample, bitDepth);
					final alpha = transparentGray >= 0 && sample == transparentGray ? 0 : 255;
					writeRgba(dst, gray, gray, gray, alpha);
				case 2:
					final rSample = readSample(line, bitDepth, x, 3, 0);
					final gSample = readSample(line, bitDepth, x, 3, 1);
					final bSample = readSample(line, bitDepth, x, 3, 2);
					final alpha = transparentRgb != null && rSample == transparentRgb[0] && gSample == transparentRgb[1]
						&& bSample == transparentRgb[2] ? 0 : 255;
					writeRgba(dst, sampleToByte(rSample, bitDepth), sampleToByte(gSample, bitDepth), sampleToByte(bSample, bitDepth), alpha);
				case 3:
					final index = readSample(line, bitDepth, x, 1, 0);
					if (index * 3 + 2 >= palette.length)
						DecodeTools.fail('PNG palette index out of range: $index');
					final alpha = paletteAlpha != null && index < paletteAlpha.length ? paletteAlpha.get(index) : 255;
					writeRgba(dst, palette.get(index * 3), palette.get(index * 3 + 1), palette.get(index * 3 + 2), alpha);
				case 4:
					final graySample = readSample(line, bitDepth, x, 2, 0);
					final alphaSample = readSample(line, bitDepth, x, 2, 1);
					final gray = sampleToByte(graySample, bitDepth);
					writeRgba(dst, gray, gray, gray, sampleToByte(alphaSample, bitDepth));
				case 6:
					writeRgba(dst, sampleToByte(readSample(line, bitDepth, x, 4, 0), bitDepth), sampleToByte(readSample(line, bitDepth, x, 4, 1), bitDepth),
						sampleToByte(readSample(line, bitDepth, x, 4, 2), bitDepth), sampleToByte(readSample(line, bitDepth, x, 4, 3), bitDepth));
				case _:
			}
		}
	}

	inline function writeRgba(offset:Int, r:Int, g:Int, b:Int, a:Int):Void {
		pixels.set(offset + 0, r);
		pixels.set(offset + 1, g);
		pixels.set(offset + 2, b);
		pixels.set(offset + 3, a);
	}

	function readSample(line:Bytes, bitDepth:Int, pixel:Int, channels:Int, channel:Int):Int {
		return switch bitDepth {
			case 1, 2, 4:
				DecodeTools.unpackBits(line, bitDepth, pixel * channels + channel);
			case 8:
				line.get(pixel * channels + channel);
			case 16:
				final offset = (pixel * channels + channel) * 2;
				DecodeTools.u16BE(line, offset);
			case _:
				DecodeTools.fail('Unsupported PNG bit depth: $bitDepth');
		}
	}

	inline function sampleToByte(sample:Int, bitDepth:Int):Int {
		return switch bitDepth {
			case 16: Std.int(sample * 255 / 65535 + 0.5);
			case _: DecodeTools.scaleToByte(sample, bitDepth);
		}
	}

	inline function reducedSize(size:Int, start:Int, step:Int):Int {
		if (size <= start)
			return 0;
		return Std.int((size - start + step - 1) / step);
	}
}
