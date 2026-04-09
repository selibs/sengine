package s.assets.internal.image.format;

import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.FPHelper;
import haxe.zip.Uncompress;

class DecodeTools {
	public static inline function fail<T>(message:String):T
		throw new Exception(message);

	public static inline function ensureAvailable(bytes:Bytes, offset:Int, size:Int, what:String):Void {
		if (size < 0 || offset < 0 || offset > bytes.length - size)
			fail('Unexpected end of data while reading $what');
	}

	public static inline function u8(bytes:Bytes, offset:Int):Int
		return bytes.get(offset);

	public static inline function u16LE(bytes:Bytes, offset:Int):Int
		return bytes.get(offset) | (bytes.get(offset + 1) << 8);

	public static inline function u16BE(bytes:Bytes, offset:Int):Int
		return (bytes.get(offset) << 8) | bytes.get(offset + 1);

	public static inline function s16LE(bytes:Bytes, offset:Int):Int {
		final value = u16LE(bytes, offset);
		return (value & 0x8000) != 0 ? value - 0x10000 : value;
	}

	public static inline function s16BE(bytes:Bytes, offset:Int):Int {
		final value = u16BE(bytes, offset);
		return (value & 0x8000) != 0 ? value - 0x10000 : value;
	}

	public static inline function i32LE(bytes:Bytes, offset:Int):Int
		return bytes.getInt32(offset);

	public static inline function i32BE(bytes:Bytes, offset:Int):Int
		return bytes.get(offset) << 24 | bytes.get(offset + 1) << 16 | bytes.get(offset + 2) << 8 | bytes.get(offset + 3);

	public static inline function u32LE(bytes:Bytes, offset:Int):Int
		return i32LE(bytes, offset);

	public static inline function u32BE(bytes:Bytes, offset:Int):Int
		return i32BE(bytes, offset);

	public static inline function float32LE(bytes:Bytes, offset:Int):Float
		return FPHelper.i32ToFloat(i32LE(bytes, offset));

	public static inline function float32BE(bytes:Bytes, offset:Int):Float
		return FPHelper.i32ToFloat(i32BE(bytes, offset));

	public static inline function readTag(bytes:Bytes, offset:Int, length:Int):String {
		ensureAvailable(bytes, offset, length, "tag");
		return bytes.getString(offset, length);
	}

	public static function concat(chunks:Array<Bytes>):Bytes {
		var total = 0;
		for (chunk in chunks)
			total += chunk.length;

		final out = Bytes.alloc(total);
		var offset = 0;
		for (chunk in chunks) {
			out.blit(offset, chunk, 0, chunk.length);
			offset += chunk.length;
		}
		return out;
	}

	public static inline function scaleToByte(value:Int, bits:Int):Int {
		if (bits <= 0)
			return 0;
		if (bits >= 8)
			return bits == 8 ? value & 0xff : Std.int(((value & ((1 << bits) - 1)) * 255) / ((1 << bits) - 1) + 0.5);
		return Std.int((value * 255) / ((1 << bits) - 1) + 0.5);
	}

	public static inline function paeth(a:Int, b:Int, c:Int):Int {
		final p = a + b - c;
		final pa = p > a ? p - a : a - p;
		final pb = p > b ? p - b : b - p;
		final pc = p > c ? p - c : c - p;
		return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
	}

	public static function unpackBits(line:Bytes, bitDepth:Int, index:Int):Int {
		return unpackBitsAt(line, 0, bitDepth, index);
	}

	public static function unpackBitsAt(bytes:Bytes, baseOffset:Int, bitDepth:Int, index:Int):Int {
		return switch bitDepth {
			case 1:
				final byte = bytes.get(baseOffset + (index >> 3));
				(byte >> (7 - (index & 7))) & 0x1;
			case 2:
				final byte = bytes.get(baseOffset + (index >> 2));
				(byte >> ((3 - (index & 3)) << 1)) & 0x3;
			case 4:
				final byte = bytes.get(baseOffset + (index >> 1));
				(byte >> ((1 - (index & 1)) << 2)) & 0xf;
			case _:
				fail('Unsupported packed bit depth: $bitDepth');
		}
	}

	public static function packBitsDecode(bytes:Bytes, expectedLength:Int):Bytes {
		final out = Bytes.alloc(expectedLength);
		var src = 0;
		var dst = 0;

		while (dst < expectedLength) {
			ensureAvailable(bytes, src, 1, "PackBits header");
			final header = bytes.get(src++);

			if (header <= 127) {
				final count = header + 1;
				ensureAvailable(bytes, src, count, "PackBits literal");
				out.blit(dst, bytes, src, count);
				src += count;
				dst += count;
			} else if (header >= 129) {
				final count = 257 - header;
				ensureAvailable(bytes, src, 1, "PackBits repeat value");
				final value = bytes.get(src++);
				for (i in 0...count)
					out.set(dst++, value);
			}
		}

		return out;
	}

	public static inline function inflate(bytes:Bytes):Bytes
		return Uncompress.run(bytes);

	public static inline function toneMap(value:Float):Int {
		if (value <= 0)
			return 0;
		final mapped = value / (1 + value);
		final corrected = Math.pow(mapped, 1 / 2.2);
		return Std.int(corrected * 255 + 0.5);
	}

	public static inline function clampByte(value:Float):Int {
		if (value <= 0)
			return 0;
		if (value >= 255)
			return 255;
		return Std.int(value + 0.5);
	}

	public static inline function trailingZeros(mask:Int):Int {
		if (mask == 0)
			return 0;
		var value = mask;
		var count = 0;
		while ((value & 1) == 0) {
			value >>>= 1;
			count++;
		}
		return count;
	}

	public static inline function bitCount(mask:Int):Int {
		var value = mask;
		var count = 0;
		while (value != 0) {
			count += value & 1;
			value >>>= 1;
		}
		return count;
	}

	public static inline function extractMasked(value:Int, mask:Int):Int {
		if (mask == 0)
			return 255;
		final shift = trailingZeros(mask);
		final bits = bitCount(mask);
		return scaleToByte((value & mask) >>> shift, bits);
	}

	public static function readCString(bytes:Bytes, offset:Int, end:Int):{value:String, next:Int} {
		var pos = offset;
		while (pos < end && bytes.get(pos) != 0)
			pos++;
		if (pos >= end)
			fail("Unterminated string");
		return {
			value: bytes.getString(offset, pos - offset),
			next: pos + 1
		};
	}

	public static inline function halfToFloat(value:Int):Float {
		final sign = (value & 0x8000) != 0 ? -1.0 : 1.0;
		final exponent = (value >> 10) & 0x1f;
		final mantissa = value & 0x03ff;

		if (exponent == 0) {
			if (mantissa == 0)
				return sign * 0.0;
			return sign * Math.pow(2, -14) * (mantissa / 1024.0);
		}

		if (exponent == 31)
			return mantissa == 0 ? sign * Math.POSITIVE_INFINITY : Math.NaN;

		return sign * Math.pow(2, exponent - 15) * (1.0 + mantissa / 1024.0);
	}
}
