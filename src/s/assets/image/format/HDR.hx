package s.assets.image.format;

import haxe.io.Bytes;

class HDR extends ImageDecoder {
	static inline final pixelStride:Int = 4;

	var offset:Int = 0;
	var buffer:Bytes;
	var flipX:Bool = false;
	var flipY:Bool = false;

	public function decode(bytes:Bytes):Void {
		buffer = bytes;
		offset = 0;
		flipX = false;
		flipY = false;

		var foundFormat = false;
		while (offset < buffer.length) {
			final line = readLine();
			if (line == "")
				continue;
			if (line.indexOf("FORMAT=32-bit_rle_rgbe") == 0)
				foundFormat = true;
			if (line.length > 2 && (line.indexOf("-Y ") == 0 || line.indexOf("+Y ") == 0)) {
				parseResolution(line);
				break;
			}
		}

		if (!foundFormat)
			DecodeTools.fail("Unsupported HDR format");
		if (width <= 0 || height <= 0)
			DecodeTools.fail("Invalid HDR size");

		pixels = Bytes.alloc(width * height * pixelStride);
		final scanline = Bytes.alloc(width * 4);

		for (y in 0...height) {
			readScanline(scanline);
			for (x in 0...width) {
				final src = x * 4;
				final dstX = flipX ? width - 1 - x : x;
				final dstY = flipY ? height - 1 - y : y;
				final dst = (dstY * width + dstX) * pixelStride;
				final exponent = scanline.get(src + 3);
				if (exponent == 0) {
					pixels.set(dst + 0, 0);
					pixels.set(dst + 1, 0);
					pixels.set(dst + 2, 0);
					pixels.set(dst + 3, 255);
					continue;
				}

				final factor = Math.pow(2.0, exponent - 128.0);
				pixels.set(dst + 0, DecodeTools.toneMap((scanline.get(src + 0) / 255.0) * factor));
				pixels.set(dst + 1, DecodeTools.toneMap((scanline.get(src + 1) / 255.0) * factor));
				pixels.set(dst + 2, DecodeTools.toneMap((scanline.get(src + 2) / 255.0) * factor));
				pixels.set(dst + 3, 255);
			}
		}

		finish();
	}

	function parseResolution(line:String):Void {
		final parts = line.split(" ");
		if (parts.length < 4)
			DecodeTools.fail('Invalid HDR resolution line: $line');

		final yAxis = parts[0];
		final yValue = Std.parseInt(parts[1]);
		final xAxis = parts[2];
		final xValue = Std.parseInt(parts[3]);
		if (yValue == null || xValue == null)
			DecodeTools.fail('Invalid HDR resolution line: $line');
		if ((yAxis != "-Y" && yAxis != "+Y") || (xAxis != "+X" && xAxis != "-X"))
			DecodeTools.fail('Unsupported HDR axis order: $line');

		height = yValue;
		width = xValue;
		flipY = yAxis == "+Y";
		flipX = xAxis == "-X";
	}

	function readScanline(out:Bytes):Void {
		DecodeTools.ensureAvailable(buffer, offset, 4, "HDR scanline header");
		final b0 = buffer.get(offset++);
		final b1 = buffer.get(offset++);
		final b2 = buffer.get(offset++);
		final b3 = buffer.get(offset++);

		if (width < 8 || width > 0x7fff || b0 != 2 || b1 != 2 || (b2 & 0x80) != 0) {
			readFlatScanline(out, b0, b1, b2, b3);
			return;
		}

		final scanlineWidth = (b2 << 8) | b3;
		if (scanlineWidth != width)
			DecodeTools.fail('HDR scanline width mismatch: $scanlineWidth != $width');

		final tmp = Bytes.alloc(width);
		for (channel in 0...4) {
			var x = 0;
			while (x < width) {
				DecodeTools.ensureAvailable(buffer, offset, 2, "HDR RLE packet");
				final count = buffer.get(offset++);
				final value = buffer.get(offset++);

				if (count > 128) {
					final runLength = count - 128;
					if (runLength <= 0 || x + runLength > width)
						DecodeTools.fail("Corrupt HDR run-length packet");
					for (i in 0...runLength)
						tmp.set(x++, value);
				} else {
					final literalLength = count;
					if (literalLength <= 0 || x + literalLength > width)
						DecodeTools.fail("Corrupt HDR literal packet");
					tmp.set(x++, value);
					if (literalLength > 1) {
						DecodeTools.ensureAvailable(buffer, offset, literalLength - 1, "HDR literal data");
						for (i in 1...literalLength)
							tmp.set(x++, buffer.get(offset++));
					}
				}
			}

			for (i in 0...width)
				out.set(i * 4 + channel, tmp.get(i));
		}
	}

	function readFlatScanline(out:Bytes, r0:Int, g0:Int, b0:Int, e0:Int):Void {
		var x = 0;
		var shift = 0;
		var prevR = 0;
		var prevG = 0;
		var prevB = 0;
		var prevE = 0;

		while (x < width) {
			final r = x == 0 ? r0 : nextByte("HDR flat scanline");
			final g = x == 0 ? g0 : nextByte("HDR flat scanline");
			final b = x == 0 ? b0 : nextByte("HDR flat scanline");
			final e = x == 0 ? e0 : nextByte("HDR flat scanline");

			if (r == 1 && g == 1 && b == 1) {
				final count = e << shift;
				if (count <= 0 || x == 0 || x + count > width)
					DecodeTools.fail("Corrupt HDR old-style RLE packet");
				for (_ in 0...count) {
					final dst = x * 4;
					out.set(dst + 0, prevR);
					out.set(dst + 1, prevG);
					out.set(dst + 2, prevB);
					out.set(dst + 3, prevE);
					x++;
				}
				shift += 8;
				continue;
			}

			final dst = x * 4;
			out.set(dst + 0, r);
			out.set(dst + 1, g);
			out.set(dst + 2, b);
			out.set(dst + 3, e);
			prevR = r;
			prevG = g;
			prevB = b;
			prevE = e;
			x++;
			shift = 0;
		}
	}

	function readLine():String {
		if (offset >= buffer.length)
			return "";

		final start = offset;
		while (offset < buffer.length) {
			final b = buffer.get(offset++);
			if (b == 10)
				break;
		}

		var length = offset - start;
		if (length > 0 && buffer.get(offset - 1) == 10)
			length--;
		if (length > 0 && buffer.get(start + length - 1) == 13)
			length--;

		return buffer.getString(start, length);
	}

	inline function nextByte(what:String):Int {
		DecodeTools.ensureAvailable(buffer, offset, 1, what);
		return buffer.get(offset++);
	}
}
