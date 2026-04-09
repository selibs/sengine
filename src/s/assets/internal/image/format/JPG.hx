package s.assets.internal.image.format;

import haxe.ds.Vector;
import haxe.io.Bytes;

private enum JpegFilter {
	Fast;
	Chromatic;
}

private abstract JpegBytes(Bytes) {
	public inline function new(bytes:Bytes) {
		this = bytes;
	}

	@:arrayAccess inline function get(index:Int):Int {
		return this.get(index);
	}

	@:arrayAccess inline function set(index:Int, value:Int):Void {
		this.set(index, value);
	}
}

private typedef JpegComponent = {
	var cid:Int;
	var ssx:Int;
	var ssy:Int;
	var width:Int;
	var height:Int;
	var stride:Int;
	var qtsel:Int;
	var actabsel:Int;
	var dctabsel:Int;
	var dcpred:Int;
	var pixels:Bytes;
}

class JPG extends ImageDecoder {
	static inline final blockSize = 64;

	static inline final w1 = 2841;
	static inline final w2 = 2676;
	static inline final w3 = 2408;
	static inline final w5 = 1609;
	static inline final w6 = 1108;
	static inline final w7 = 565;

	static inline final cf4a = -9;
	static inline final cf4b = 111;
	static inline final cf4c = 29;
	static inline final cf4d = -3;
	static inline final cf3a = 28;
	static inline final cf3b = 109;
	static inline final cf3c = -9;
	static inline final cf3x = 104;
	static inline final cf3y = 27;
	static inline final cf3z = -3;
	static inline final cf2a = 139;
	static inline final cf2b = -11;

	static final zigZag = Vector.fromArrayCopy([
		 0,  1,  8, 16,  9,  2,  3, 10,
		17, 24, 32, 25, 18, 11,  4,  5,
		12, 19, 26, 33, 40, 48, 41, 34,
		27, 20, 13,  6,  7, 14, 21, 28,
		35, 42, 49, 56, 57, 50, 43, 36,
		29, 22, 15, 23, 30, 37, 44, 51,
		58, 59, 52, 45, 38, 31, 39, 46,
		53, 60, 61, 54, 47, 55, 62, 63
	]);

	var bytes:Bytes;
	var pos:Int;
	var size:Int;
	var length:Int;

	var componentCount:Int;
	var components:Vector<JpegComponent>;
	var counts:Vector<Int>;
	var quantTables:Vector<Vector<Int>>;
	var quantUsed:Int;
	var quantAvailable:Int;
	var vlcTables:Vector<Bytes>;
	var block:Vector<Int>;
	var progressive:Bool;

	var macroblockWidth:Int;
	var macroblockHeight:Int;
	var macroblockPixelWidth:Int;
	var macroblockPixelHeight:Int;
	var restartInterval:Int;
	var bitBuffer:Int;
	var bitCount:Int;

	var vlcCode:Int;
	var filter:JpegFilter;

	public function new(asset) {
		super(asset);
		components = Vector.fromArrayCopy([makeComponent(), makeComponent(), makeComponent()]);
		quantTables = Vector.fromArrayCopy([new Vector(64), new Vector(64), new Vector(64), new Vector(64)]);
		counts = new Vector(16);
		vlcTables = Vector.fromArrayCopy([null, null, null, null, null, null, null, null]);
		block = new Vector(blockSize);
		filter = Chromatic;
	}

	public function decode(bytes:Bytes):Void {
		init(bytes, 0, bytes.length, Chromatic);
		decodeImage();
		cleanup();
		finish();
	}

	inline function makeComponent():JpegComponent {
		return {
			cid: 0,
			ssx: 0,
			ssy: 0,
			width: 0,
			height: 0,
			stride: 0,
			qtsel: 0,
			actabsel: 0,
			dctabsel: 0,
			dcpred: 0,
			pixels: null
		};
	}

	function init(input:Bytes, position:Int, length:Int, filter:JpegFilter):Void {
		bytes = input;
		pos = position;
		size = length;
		this.filter = filter;
		quantUsed = 0;
		quantAvailable = 0;
		restartInterval = 0;
		this.length = 0;
		bitBuffer = 0;
		bitCount = 0;
		progressive = false;
		width = 0;
		height = 0;
		componentCount = 0;
		pixels = null;
		for (i in 0...components.length) {
			final c = components[i];
			c.dcpred = 0;
			c.pixels = null;
		}
		for (i in 0...vlcTables.length)
			if (vlcTables[i] == null)
				vlcTables[i] = Bytes.alloc(1 << 17);
	}

	function cleanup():Void {
		bytes = null;
		for (i in 0...components.length)
			components[i].pixels = null;
	}

	inline function fail<T>(message:String):T
		return DecodeTools.fail(message);

	inline function ensure(condition:Bool, message:String):Void {
		if (!condition)
			fail(message);
	}

	inline function get(offset:Int):Int
		return bytes.get(pos + offset);

	inline function read16(offset:Int):Int
		return (get(offset) << 8) | get(offset + 1);

	inline function skip(count:Int):Void {
		pos += count;
		size -= count;
		length -= count;
		ensure(size >= 0, "Invalid JPEG stream");
	}

	inline function decodeLength():Void {
		ensure(size >= 2, "Truncated JPEG segment");
		length = read16(0);
		ensure(length <= size, "Invalid JPEG segment length");
		skip(2);
	}

	inline function skipMarker():Void {
		decodeLength();
		skip(length);
	}

	inline function byteAlign():Void {
		bitCount &= 0xF8;
	}

	function showBits(bits:Int):Int {
		if (bits == 0)
			return 0;

		while (bitCount < bits) {
			if (size <= 0) {
				bitBuffer = (bitBuffer << 8) | 0xFF;
				bitCount += 8;
				continue;
			}

			final next = get(0);
			pos++;
			size--;
			bitBuffer = (bitBuffer << 8) | next;
			bitCount += 8;

			if (next == 0xFF) {
				ensure(size > 0, "Invalid JPEG entropy stream");
				final marker = get(0);
				pos++;
				size--;
				switch marker {
					case 0x00, 0xFF:
					case 0xD9:
						size = 0;
					case _:
						ensure((marker & 0xF8) == 0xD0, 'Unexpected JPEG marker in scan: 0x${StringTools.hex(marker, 2)}');
						bitBuffer = (bitBuffer << 8) | marker;
						bitCount += 8;
				}
			}
		}

		return (bitBuffer >> (bitCount - bits)) & ((1 << bits) - 1);
	}

	inline function skipBits(bits:Int):Void {
		if (bitCount < bits)
			showBits(bits);
		bitCount -= bits;
	}

	inline function getBits(bits:Int):Int {
		final value = showBits(bits);
		bitCount -= bits;
		return value;
	}

	function decodeSOF():Void {
		decodeLength();
		ensure(length >= 9, "Invalid JPEG SOF segment");
		if (get(0) != 8)
			fail("Only 8-bit JPEG is supported");

		height = read16(1);
		width = read16(3);
		componentCount = get(5);
		skip(6);

		switch componentCount {
			case 1, 3:
			case _:
				fail('Unsupported JPEG component count: $componentCount');
		}

		ensure(length >= componentCount * 3, "Invalid JPEG SOF component data");

		var ssxMax = 0;
		var ssyMax = 0;
		for (i in 0...componentCount) {
			final c = components[i];
			c.cid = get(0);
			c.ssx = get(1) >> 4;
			c.ssy = get(1) & 15;
			c.qtsel = get(2);

			ensure(c.ssx != 0 && c.ssy != 0, "Invalid JPEG sampling factors");
			ensure((c.ssx & (c.ssx - 1)) == 0 && (c.ssy & (c.ssy - 1)) == 0, "Unsupported JPEG sampling factors");
			ensure((c.qtsel & 0xFC) == 0, "Invalid JPEG quantization table selector");

			skip(3);
			quantUsed |= 1 << c.qtsel;
			if (c.ssx > ssxMax)
				ssxMax = c.ssx;
			if (c.ssy > ssyMax)
				ssyMax = c.ssy;
		}

		if (componentCount == 1) {
			final c = components[0];
			c.ssx = 1;
			c.ssy = 1;
			ssxMax = 1;
			ssyMax = 1;
		}

		macroblockPixelWidth = ssxMax << 3;
		macroblockPixelHeight = ssyMax << 3;
		macroblockWidth = Std.int((width + macroblockPixelWidth - 1) / macroblockPixelWidth);
		macroblockHeight = Std.int((height + macroblockPixelHeight - 1) / macroblockPixelHeight);

		for (i in 0...componentCount) {
			final c = components[i];
			c.width = Std.int((width * c.ssx + ssxMax - 1) / ssxMax);
			c.height = Std.int((height * c.ssy + ssyMax - 1) / ssyMax);
			c.stride = Std.int(macroblockWidth * macroblockPixelWidth * c.ssx / ssxMax);
			ensure((c.width >= 3 || c.ssx == ssxMax) && (c.height >= 3 || c.ssy == ssyMax), "Unsupported JPEG image size");
			c.pixels = Bytes.alloc(c.stride * Std.int(macroblockHeight * macroblockPixelHeight * c.ssy / ssyMax));
		}

		skip(length);
	}

	function decodeDQT():Void {
		decodeLength();
		while (length >= 65) {
			final tableIndex = get(0);
			ensure((tableIndex & 0xFC) == 0, "Invalid JPEG quantization table index");
			quantAvailable |= 1 << tableIndex;
			final target = quantTables[tableIndex];
			for (i in 0...64)
				target[i] = get(i + 1);
			skip(65);
		}
		ensure(length == 0, "Invalid JPEG DQT segment");
	}

	function decodeDHT():Void {
		decodeLength();
		while (length >= 17) {
			var tableIndex = get(0);
			ensure((tableIndex & 0xEC) == 0, "Invalid JPEG Huffman table index");
			tableIndex = ((tableIndex >> 4) & 1) | ((tableIndex & 3) << 1);

			for (i in 0...16)
				counts[i] = get(i + 1);
			skip(17);

			final vlc = vlcTables[tableIndex];
			var writePos = 0;
			var remain = 65536;
			var spread = 65536;

			for (codeLength in 1...17) {
				spread >>= 1;
				final currentCount = counts[codeLength - 1];
				if (currentCount == 0)
					continue;
				ensure(length >= currentCount, "Truncated JPEG Huffman table");
				remain -= currentCount << (16 - codeLength);
				ensure(remain >= 0, "Invalid JPEG Huffman table");

				for (i in 0...currentCount) {
					final code = get(i);
					for (_ in 0...spread) {
						vlc.set(writePos++, codeLength);
						vlc.set(writePos++, code);
					}
				}
				skip(currentCount);
			}

			while (remain-- > 0) {
				vlc.set(writePos, 0);
				writePos += 2;
			}
		}
		ensure(length == 0, "Invalid JPEG DHT segment");
	}

	function decodeDRI():Void {
		decodeLength();
		ensure(length >= 2, "Invalid JPEG DRI segment");
		restartInterval = read16(0);
		skip(length);
	}

	function getVLC(vlc:Bytes):Int {
		var value = showBits(16);
		final bits = vlc.get(value << 1);
		ensure(bits != 0, "Invalid JPEG Huffman code");
		skipBits(bits);
		value = vlc.get((value << 1) | 1);
		vlcCode = value;
		final extraBits = value & 15;
		if (extraBits == 0)
			return 0;
		value = getBits(extraBits);
		if (value < (1 << (extraBits - 1)))
			value += ((-1) << extraBits) + 1;
		return value;
	}

	inline function clip(value:Int):Int
		return value < 0 ? 0 : value > 255 ? 255 : value;

	inline function clipFilter(value:Int):Int
		return clip((value + 64) >> 7);

	function rowIDCT(base:Int):Void {
		var x0:Int;
		var x1:Int;
		var x2:Int;
		var x3:Int;
		var x4:Int;
		var x5:Int;
		var x6:Int;
		var x7:Int;
		var x8:Int;

		if (((x1 = block[base + 4] << 11) | (x2 = block[base + 6]) | (x3 = block[base + 2]) | (x4 = block[base + 1]) | (x5 = block[base + 7]) | (x6 = block[base
			+ 5]) | (x7 = block[base + 3])) == 0) {
			final dc = block[base] << 3;
			for (i in 0...8)
				block[base + i] = dc;
			return;
		}

		x0 = (block[base] << 11) + 128;
		x8 = w7 * (x4 + x5);
		x4 = x8 + (w1 - w7) * x4;
		x5 = x8 - (w1 + w7) * x5;
		x8 = w3 * (x6 + x7);
		x6 = x8 - (w3 - w5) * x6;
		x7 = x8 - (w3 + w5) * x7;
		x8 = x0 + x1;
		x0 -= x1;
		x1 = w6 * (x3 + x2);
		x2 = x1 - (w2 + w6) * x2;
		x3 = x1 + (w2 - w6) * x3;
		x1 = x4 + x6;
		x4 -= x6;
		x6 = x5 + x7;
		x5 -= x7;
		x7 = x8 + x3;
		x8 -= x3;
		x3 = x0 + x2;
		x0 -= x2;
		x2 = (181 * (x4 + x5) + 128) >> 8;
		x4 = (181 * (x4 - x5) + 128) >> 8;
		block[base + 0] = (x7 + x1) >> 8;
		block[base + 1] = (x3 + x2) >> 8;
		block[base + 2] = (x0 + x4) >> 8;
		block[base + 3] = (x8 + x6) >> 8;
		block[base + 4] = (x8 - x6) >> 8;
		block[base + 5] = (x0 - x4) >> 8;
		block[base + 6] = (x3 - x2) >> 8;
		block[base + 7] = (x7 - x1) >> 8;
	}

	function colIDCT(base:Int, output:Bytes, outputPos:Int, stride:Int):Void {
		final out = new JpegBytes(output);
		var x0:Int;
		var x1:Int;
		var x2:Int;
		var x3:Int;
		var x4:Int;
		var x5:Int;
		var x6:Int;
		var x7:Int;
		var x8:Int;

		if (((x1 = block[base + 8 * 4] << 8) | (x2 = block[base + 8 * 6]) | (x3 = block[base + 8 * 2]) | (x4 = block[base + 8 * 1]) | (x5 = block[base + 8 * 7]) | (x6 = block[base
			+ 8 * 5]) | (x7 = block[base + 8 * 3])) == 0) {
			final dc = clip(((block[base] + 32) >> 6) + 128);
			for (_ in 0...8) {
				out[outputPos] = dc;
				outputPos += stride;
			}
			return;
		}

		x0 = (block[base] << 8) + 8192;
		x8 = w7 * (x4 + x5) + 4;
		x4 = (x8 + (w1 - w7) * x4) >> 3;
		x5 = (x8 - (w1 + w7) * x5) >> 3;
		x8 = w3 * (x6 + x7) + 4;
		x6 = (x8 - (w3 - w5) * x6) >> 3;
		x7 = (x8 - (w3 + w5) * x7) >> 3;
		x8 = x0 + x1;
		x0 -= x1;
		x1 = w6 * (x3 + x2) + 4;
		x2 = (x1 - (w2 + w6) * x2) >> 3;
		x3 = (x1 + (w2 - w6) * x3) >> 3;
		x1 = x4 + x6;
		x4 -= x6;
		x6 = x5 + x7;
		x5 -= x7;
		x7 = x8 + x3;
		x8 -= x3;
		x3 = x0 + x2;
		x0 -= x2;
		x2 = (181 * (x4 + x5) + 128) >> 8;
		x4 = (181 * (x4 - x5) + 128) >> 8;
		out[outputPos] = clip(((x7 + x1) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x3 + x2) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x0 + x4) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x8 + x6) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x8 - x6) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x0 - x4) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x3 - x2) >> 14) + 128);
		outputPos += stride;
		out[outputPos] = clip(((x7 - x1) >> 14) + 128);
	}

	function decodeBlock(component:JpegComponent, outputPos:Int):Void {
		for (i in 0...blockSize)
			block[i] = 0;

		component.dcpred += getVLC(vlcTables[component.dctabsel]);
		final quant = quantTables[component.qtsel];
		final acTable = vlcTables[component.actabsel];
		block[0] = component.dcpred * quant[0];

		var coef = 0;
		while (coef < 63) {
			final value = getVLC(acTable);
			if (vlcCode == 0)
				break;
			ensure((vlcCode & 0x0F) != 0 || vlcCode == 0xF0, "Invalid JPEG AC coefficient");
			coef += (vlcCode >> 4) + 1;
			ensure(coef <= 63, "Invalid JPEG zig-zag index");
			block[zigZag[coef]] = value * quant[coef];
		}

		for (i in 0...8)
			rowIDCT(i * 8);
		for (i in 0...8)
			colIDCT(i, component.pixels, i + outputPos, component.stride);
	}

	function decodeScan():Void {
		decodeLength();
		ensure(length >= 4 + 2 * componentCount, "Invalid JPEG SOS segment");
		if (get(0) != componentCount)
			fail("Unsupported JPEG scan/component layout");
		skip(1);

		for (i in 0...componentCount) {
			final c = components[i];
			ensure(get(0) == c.cid, "Invalid JPEG scan component id");
			ensure((get(1) & 0xEC) == 0, "Invalid JPEG Huffman selector");
			c.dctabsel = (get(1) >> 4) << 1;
			c.actabsel = ((get(1) & 3) << 1) | 1;
			skip(2);
		}

		final spectralStart = get(0);
		final spectralCount = get(1);
		final approx = get(2);
		if ((!progressive && spectralStart != 0) || (spectralCount != 63 - spectralStart) || approx != 0)
			fail("Unsupported JPEG scan mode");
		skip(length);

		var macroX = 0;
		var macroY = 0;
		var restartCount = restartInterval;
		var nextRestart = 0;

		while (true) {
			for (i in 0...componentCount) {
				final c = components[i];
				for (subY in 0...c.ssy)
					for (subX in 0...c.ssx)
						decodeBlock(c, ((macroY * c.ssy + subY) * c.stride + macroX * c.ssx + subX) << 3);
			}

			if (++macroX >= macroblockWidth) {
				macroX = 0;
				if (++macroY >= macroblockHeight)
					break;
			}

			if (restartInterval != 0 && --restartCount == 0) {
				byteAlign();
				final marker = getBits(16);
				ensure((marker & 0xFFF8) == 0xFFD0 && (marker & 7) == nextRestart, "Invalid JPEG restart marker");
				nextRestart = (nextRestart + 1) & 7;
				restartCount = restartInterval;
				for (i in 0...componentCount)
					components[i].dcpred = 0;
			}
		}
	}

	function upsample(component:JpegComponent):Void {
		var xShift = 0;
		var yShift = 0;
		while (component.width < width) {
			component.width <<= 1;
			xShift++;
		}
		while (component.height < height) {
			component.height <<= 1;
			yShift++;
		}

		final out = Bytes.alloc(component.width * component.height);
		final src = new JpegBytes(component.pixels);
		final dst = new JpegBytes(out);
		var writePos = 0;
		for (y in 0...component.height) {
			final srcOffset = (y >> yShift) * component.stride;
			for (x in 0...component.width)
				dst[writePos++] = src[(x >> xShift) + srcOffset];
		}
		component.stride = component.width;
		component.pixels = out;
	}

	function upsampleH(component:JpegComponent):Void {
		final xmax = component.width - 3;
		final out = Bytes.alloc((component.width * component.height) << 1);
		final src = new JpegBytes(component.pixels);
		final dst = new JpegBytes(out);
		var srcPos = 0;
		var dstPos = 0;

		for (_ in 0...component.height) {
			dst[dstPos] = clipFilter(cf2a * src[srcPos] + cf2b * src[srcPos + 1]);
			dst[dstPos + 1] = clipFilter(cf3x * src[srcPos] + cf3y * src[srcPos + 1] + cf3z * src[srcPos + 2]);
			dst[dstPos + 2] = clipFilter(cf3a * src[srcPos] + cf3b * src[srcPos + 1] + cf3c * src[srcPos + 2]);
			for (x in 0...xmax) {
				dst[dstPos + (x << 1) + 3] = clipFilter(cf4a * src[srcPos + x] + cf4b * src[srcPos + x + 1] + cf4c * src[srcPos + x + 2]
					+ cf4d * src[srcPos + x + 3]);
				dst[dstPos + (x << 1) + 4] = clipFilter(cf4d * src[srcPos + x] + cf4c * src[srcPos + x + 1] + cf4b * src[srcPos + x + 2]
					+ cf4a * src[srcPos + x + 3]);
			}
			srcPos += component.stride;
			dstPos += component.width << 1;
			dst[dstPos - 3] = clipFilter(cf3a * src[srcPos - 1] + cf3b * src[srcPos - 2] + cf3c * src[srcPos - 3]);
			dst[dstPos - 2] = clipFilter(cf3x * src[srcPos - 1] + cf3y * src[srcPos - 2] + cf3z * src[srcPos - 3]);
			dst[dstPos - 1] = clipFilter(cf2a * src[srcPos - 1] + cf2b * src[srcPos - 2]);
		}

		component.width <<= 1;
		component.stride = component.width;
		component.pixels = out;
	}

	function upsampleV(component:JpegComponent):Void {
		final rowWidth = component.width;
		final stride1 = component.stride;
		final stride2 = stride1 + stride1;
		final out = Bytes.alloc((component.width * component.height) << 1);
		final src = new JpegBytes(component.pixels);
		final dst = new JpegBytes(out);

		for (x in 0...rowWidth) {
			var srcPos = x;
			var dstPos = x;
			dst[dstPos] = clipFilter(cf2a * src[srcPos] + cf2b * src[srcPos + stride1]);
			dstPos += rowWidth;
			dst[dstPos] = clipFilter(cf3x * src[srcPos] + cf3y * src[srcPos + stride1] + cf3z * src[srcPos + stride2]);
			dstPos += rowWidth;
			dst[dstPos] = clipFilter(cf3a * src[srcPos] + cf3b * src[srcPos + stride1] + cf3c * src[srcPos + stride2]);
			dstPos += rowWidth;
			srcPos += stride1;
			for (_ in 0...component.height - 2) {
				dst[dstPos] = clipFilter(cf4a * src[srcPos - stride1] + cf4b * src[srcPos] + cf4c * src[srcPos + stride1] + cf4d * src[srcPos + stride2]);
				dstPos += rowWidth;
				dst[dstPos] = clipFilter(cf4d * src[srcPos - stride1] + cf4c * src[srcPos] + cf4b * src[srcPos + stride1] + cf4a * src[srcPos + stride2]);
				dstPos += rowWidth;
				srcPos += stride1;
			}
			srcPos += stride1;
			dst[dstPos] = clipFilter(cf3a * src[srcPos] + cf3b * src[srcPos - stride1] + cf3c * src[srcPos - stride2]);
			dstPos += rowWidth;
			dst[dstPos] = clipFilter(cf3x * src[srcPos] + cf3y * src[srcPos - stride1] + cf3z * src[srcPos - stride2]);
			dstPos += rowWidth;
			dst[dstPos] = clipFilter(cf2a * src[srcPos] + cf2b * src[srcPos - stride1]);
		}

		component.height <<= 1;
		component.stride = component.width;
		component.pixels = out;
	}

	function convert():Void {
		for (i in 0...componentCount) {
			final c = components[i];
			switch filter {
				case Fast:
					if (c.width < width || c.height < height)
						upsample(c);
				case Chromatic:
					while (c.width < width || c.height < height) {
						if (c.width < width)
							upsampleH(c);
						if (c.height < height)
							upsampleV(c);
					}
			}
			ensure(c.width >= width && c.height >= height, "JPEG upsampling failed");
		}

		pixels = Bytes.alloc(width * height * 4);
		final dst = new JpegBytes(pixels);
		var out = 0;

		if (componentCount == 3) {
			final yData = new JpegBytes(components[0].pixels);
			final cbData = new JpegBytes(components[1].pixels);
			final crData = new JpegBytes(components[2].pixels);
			var ky = 0;
			var kcb = 0;
			var kcr = 0;
			for (_ in 0...height) {
				for (_ in 0...width) {
					final y = yData[ky++] << 8;
					final cb = cbData[kcb++] - 128;
					final cr = crData[kcr++] - 128;
					dst[out++] = clip((y + 359 * cr + 128) >> 8);
					dst[out++] = clip((y - 88 * cb - 183 * cr + 128) >> 8);
					dst[out++] = clip((y + 454 * cb + 128) >> 8);
					dst[out++] = 0xFF;
				}
				ky += components[0].stride - width;
				kcb += components[1].stride - width;
				kcr += components[2].stride - width;
			}
		} else if (componentCount == 1) {
			final gray = new JpegBytes(components[0].pixels);
			var srcPos = 0;
			for (_ in 0...height) {
				for (_ in 0...width) {
					final value = gray[srcPos++];
					dst[out++] = value;
					dst[out++] = value;
					dst[out++] = value;
					dst[out++] = 0xFF;
				}
				srcPos += components[0].stride - width;
			}
		} else {
			fail('Unsupported JPEG component count: $componentCount');
		}
	}

	function decodeImage():Void {
		if (size < 2 || get(0) != 0xFF || get(1) != 0xD8)
			fail("Invalid JPEG signature");

		skip(2);
		while (true) {
			ensure(size >= 2 && get(0) == 0xFF, "Invalid JPEG marker stream");
			skip(2);
			final marker = get(-1);

			switch marker {
				case 0xC0:
					decodeSOF();
				case 0xC2:
					progressive = true;
					fail("Progressive JPEG is not supported");
				case 0xDB:
					decodeDQT();
				case 0xC4:
					decodeDHT();
				case 0xDD:
					decodeDRI();
				case 0xDA:
					decodeScan();
					break;
				case 0xFE:
					skipMarker();
				case 0xC3:
					fail("Lossless JPEG is not supported");
				case _:
					switch marker & 0xF0 {
						case 0xE0:
							skipMarker();
						case 0xC0:
							fail('Unsupported JPEG SOF marker: 0x${StringTools.hex(marker, 2)}');
						case _:
							fail('Unsupported JPEG marker: 0x${StringTools.hex(marker, 2)}');
					}
			}
		}

		convert();
	}
}
