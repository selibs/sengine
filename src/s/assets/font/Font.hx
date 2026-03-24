package s.assets.font;

import haxe.ds.IntMap;
import haxe.ds.Vector;
import kha.Blob;
import kha.Kravur;
import kha.graphics2.truetype.StbTruetype;
import s.assets.Assets;

class Font extends Asset {
	static inline final sdfOversample:Int = 4;
	static inline final sdfSpread:Int = 8;
	static inline final sdfPadding:Int = sdfSpread + 1;
	static inline final sdfInf:Float = 1e20;

	static function bakeFontBitmap(data:Blob, offset:Int, pixel_height:Float, pixels:Blob, pw:Int, ph:Int, chars:Array<Int>,
			chardata:Vector<Stbtt_bakedchar>):Int @:privateAccess {
		var scale:Float;
		var x:Int, y:Int, bottom_y:Int;
		var f:Stbtt_fontinfo = new Stbtt_fontinfo();
		if (!StbTruetype.stbtt_InitFont(f, data, offset))
			return -1;
		x = y = 1;
		bottom_y = 1;

		scale = StbTruetype.stbtt_ScaleForPixelHeight(f, pixel_height);

		var i = 0;
		for (index in chars) {
			var advance:Int, lsb:Int, x0:Int, y0:Int, x1:Int, y1:Int, gw:Int, gh:Int;
			var g:Int = StbTruetype.stbtt_FindGlyphIndex(f, index);
			var metrics = StbTruetype.stbtt_GetGlyphHMetrics(f, g);
			advance = metrics.advanceWidth;
			lsb = metrics.leftSideBearing;
			var rect = StbTruetype.stbtt_GetGlyphBitmapBox(f, g, scale, scale);
			x0 = rect.x0;
			y0 = rect.y0;
			x1 = rect.x1;
			y1 = rect.y1;
			gw = x1 - x0;
			gh = y1 - y0;
			if (gw > 0 && gh > 0 && x + gw + sdfPadding * 2 + 1 >= pw) {
				y = bottom_y;
				x = 1; // advance to next row
			}
			if (gw > 0 && gh > 0 && y + gh + sdfPadding * 2 + 1 >= ph) // check if it fits vertically AFTER potentially moving to next row
				return -i;

			if (gw > 0 && gh > 0) {
				StbTruetype.STBTT_assert(x + gw + sdfPadding * 2 < pw);
				StbTruetype.STBTT_assert(y + gh + sdfPadding * 2 < ph);
				chardata[i].x0 = x;
				chardata[i].y0 = y;
				chardata[i].x1 = x + gw + sdfPadding * 2;
				chardata[i].y1 = y + gh + sdfPadding * 2;
				chardata[i].xoff = x0 - sdfPadding;
				chardata[i].yoff = y0 - sdfPadding;
				x = x + gw + sdfPadding * 2 + 1;
				if (y + gh + sdfPadding * 2 + 1 > bottom_y)
					bottom_y = y + gh + sdfPadding * 2 + 1;
			} else {
				chardata[i].x0 = x;
				chardata[i].y0 = y;
				chardata[i].x1 = x;
				chardata[i].y1 = y;
				chardata[i].xoff = x0;
				chardata[i].yoff = y0;
			}
			chardata[i].xadvance = scale * advance / sdfOversample;
			chardata[i].xoff /= sdfOversample;
			chardata[i].yoff /= sdfOversample;
			++i;
		}
		for (i in 0...pw * ph)
			pixels.writeU8(i, 0); // background of 0 around pixels
		i = 0;
		var ch:Stbtt_bakedchar;
		for (index in chars) { // bake bitmap if fits
			var g:Int = StbTruetype.stbtt_FindGlyphIndex(f, index);
			ch = chardata[i];
			final gw = ch.x1 - ch.x0 - sdfPadding * 2;
			final gh = ch.y1 - ch.y0 - sdfPadding * 2;
			if (gw > 0 && gh > 0)
				StbTruetype.stbtt_MakeGlyphBitmap(f, pixels, ch.x0 + sdfPadding + (ch.y0 + sdfPadding) * pw, gw, gh, pw, scale, scale, g);
			++i;
		}

		for (i in 0...chardata.length) {
			ch = chardata[i];
			if (ch.x1 > ch.x0 && ch.y1 > ch.y0)
				buildGlyphSdf(pixels, pw, ch);
		}
		return bottom_y;
	}

	static function estimateAtlasSize(data:Blob, offset:Int, pixelHeight:Float, chars:Array<Int>):{width:Int, height:Int} {
		var f:Stbtt_fontinfo = new Stbtt_fontinfo();
		if (!StbTruetype.stbtt_InitFont(f, data, offset))
			return {width: 64, height: 32};

		final scale = StbTruetype.stbtt_ScaleForPixelHeight(f, pixelHeight);
		var maxPackedWidth = 1;
		var maxPackedHeight = 1;
		var totalArea = 0.0;

		for (index in chars) {
			var g:Int = StbTruetype.stbtt_FindGlyphIndex(f, index);
			var rect = StbTruetype.stbtt_GetGlyphBitmapBox(f, g, scale, scale);
			var gw = rect.x1 - rect.x0;
			var gh = rect.y1 - rect.y0;
			if (gw > 0 && gh > 0) {
				var packedWidth = gw + sdfPadding * 2 + 1;
				var packedHeight = gh + sdfPadding * 2 + 1;
				if (packedWidth > maxPackedWidth)
					maxPackedWidth = packedWidth;
				if (packedHeight > maxPackedHeight)
					maxPackedHeight = packedHeight;
				totalArea += packedWidth * packedHeight;
			}
		}

		var width = nextPow2(Std.int(Math.max(64.0, Math.sqrt(Math.max(totalArea, 1.0)))));
		if (width < maxPackedWidth)
			width = nextPow2(maxPackedWidth);
		var height = nextPow2(Std.int(Math.max(32.0, totalArea / width)));
		if (height < maxPackedHeight)
			height = nextPow2(maxPackedHeight);

		while (!canPackAtlas(data, offset, pixelHeight, chars, width, height)) {
			if (height < width)
				height *= 2;
			else
				width *= 2;
		}

		return {width: width, height: height};
	}

	static function canPackAtlas(data:Blob, offset:Int, pixelHeight:Float, chars:Array<Int>, pw:Int, ph:Int):Bool {
		var f:Stbtt_fontinfo = new Stbtt_fontinfo();
		if (!StbTruetype.stbtt_InitFont(f, data, offset))
			return false;

		final scale = StbTruetype.stbtt_ScaleForPixelHeight(f, pixelHeight);
		var x = 1;
		var y = 1;
		var bottom_y = 1;

		for (index in chars) {
			var g:Int = StbTruetype.stbtt_FindGlyphIndex(f, index);
			var rect = StbTruetype.stbtt_GetGlyphBitmapBox(f, g, scale, scale);
			var gw = rect.x1 - rect.x0;
			var gh = rect.y1 - rect.y0;
			if (gw > 0 && gh > 0 && x + gw + sdfPadding * 2 + 1 >= pw) {
				y = bottom_y;
				x = 1;
			}
			if (gw > 0 && gh > 0 && y + gh + sdfPadding * 2 + 1 >= ph)
				return false;
			if (gw > 0 && gh > 0) {
				x += gw + sdfPadding * 2 + 1;
				var glyphBottom = y + gh + sdfPadding * 2 + 1;
				if (glyphBottom > bottom_y)
					bottom_y = glyphBottom;
			}
		}

		return true;
	}

	static inline function nextPow2(value:Int):Int {
		var result = 1;
		while (result < value)
			result <<= 1;
		return result;
	}

	static function buildGlyphSdf(pixels:Blob, atlasWidth:Int, glyph:Stbtt_bakedchar) {
		final width = glyph.x1 - glyph.x0;
		final height = glyph.y1 - glyph.y0;
		if (width <= 0 || height <= 0)
			return;

		final size = width * height;
		final distToInside = new Vector<Float>(size);
		final distToOutside = new Vector<Float>(size);
		for (y in 0...height)
			for (x in 0...width) {
				final coverage = pixels.readU8(glyph.x0 + x + (glyph.y0 + y) * atlasWidth) / 255.0;
				final idx = y * width + x;
				if (coverage <= 0.0) {
					distToInside[idx] = sdfInf;
					distToOutside[idx] = 0.0;
				} else if (coverage >= 1.0) {
					distToInside[idx] = 0.0;
					distToOutside[idx] = sdfInf;
				} else {
					final edge = 0.5 - coverage;
					distToInside[idx] = edge < 0.0 ? edge * edge : 0.0;
					distToOutside[idx] = edge > 0.0 ? edge * edge : 0.0;
				}
			}

		final insideField = edt2d(distToInside, width, height);
		final outsideField = edt2d(distToOutside, width, height);

		for (y in 0...height) {
			for (x in 0...width) {
				final idx = y * width + x;
				final signed = Math.sqrt(outsideField[idx]) - Math.sqrt(insideField[idx]);
				final normalized = Math.max(0.0, Math.min(1.0, 0.5 + signed / (2.0 * sdfSpread)));
				pixels.writeU8(glyph.x0 + x + (glyph.y0 + y) * atlasWidth, Std.int(Math.round(normalized * 255.0)));
			}
		}
	}

	static function edt2d(source:Vector<Float>, width:Int, height:Int):Vector<Float> {
		final tmp = new Vector<Float>(width * height);
		final out = new Vector<Float>(width * height);
		final f = new Vector<Float>(Std.int(Math.max(width, height)));
		final d = new Vector<Float>(Std.int(Math.max(width, height)));
		final v = new Vector<Int>(Std.int(Math.max(width, height)));
		final z = new Vector<Float>(Std.int(Math.max(width, height)) + 1);

		for (x in 0...width) {
			for (y in 0...height)
				f[y] = source[y * width + x];
			edt1d(f, d, v, z, height);
			for (y in 0...height)
				tmp[y * width + x] = d[y];
		}

		for (y in 0...height) {
			for (x in 0...width)
				f[x] = tmp[y * width + x];
			edt1d(f, d, v, z, width);
			for (x in 0...width)
				out[y * width + x] = d[x];
		}

		return out;
	}

	static inline function edtIntersection(f:Vector<Float>, q:Int, v:Int):Float
		return ((f[q] + q * q) - (f[v] + v * v)) / (2.0 * (q - v));

	static function edt1d(f:Vector<Float>, d:Vector<Float>, v:Vector<Int>, z:Vector<Float>, length:Int) {
		var k = 0;
		v[0] = 0;
		z[0] = Math.NEGATIVE_INFINITY;
		z[1] = Math.POSITIVE_INFINITY;

		for (q in 1...length) {
			var s = edtIntersection(f, q, v[k]);
			while (k > 0 && s <= z[k]) {
				--k;
				s = edtIntersection(f, q, v[k]);
			}
			++k;
			v[k] = q;
			z[k] = s;
			z[k + 1] = Math.POSITIVE_INFINITY;
		}

		k = 0;
		for (q in 0...length) {
			while (z[k + 1] < q)
				++k;
			final dx = q - v[k];
			d[q] = dx * dx + f[v[k]];
		}
	}

	var oldGlyphs:Array<Int>;
	var fontIndex:Int;
	var atlases:IntMap<FontAtlas> = new IntMap<FontAtlas>();

	public function getAtlas(size:Int) @:privateAccess {
		final bakedFontSize = size * sdfOversample;
		var glyphs = kha.graphics2.Graphics.fontGlyphs;

		if (glyphs != oldGlyphs) {
			oldGlyphs = glyphs;
			// save first/last chars of sequences
			KravurImage.charBlocks = [glyphs[0]];
			var nextChar = KravurImage.charBlocks[0] + 1;
			for (i in 1...glyphs.length) {
				if (glyphs[i] != nextChar) {
					KravurImage.charBlocks.push(glyphs[i - 1]);
					KravurImage.charBlocks.push(glyphs[i]);
					nextChar = glyphs[i] + 1;
				} else
					nextChar++;
			}
			KravurImage.charBlocks.push(glyphs[glyphs.length - 1]);
		}

		var index = fontIndex * 10000000 + bakedFontSize * 10000 + glyphs.length;
		var atlas = atlases.get(index);
		if (atlas != null)
			return atlas;

		var offset = StbTruetype.stbtt_GetFontOffsetForIndex(blob, fontIndex);
		if (offset == -1)
			offset = StbTruetype.stbtt_GetFontOffsetForIndex(blob, 0);

		var atlasSize = estimateAtlasSize(blob, offset, bakedFontSize, glyphs);
		var width:Int = atlasSize.width;
		var height:Int = atlasSize.height;
		var baked = new Vector<Stbtt_bakedchar>(glyphs.length);
		for (i in 0...baked.length)
			baked[i] = new Stbtt_bakedchar();

		var pixels:Blob = null;
		var status:Int = -1;
		while (status <= 0) {
			pixels = Blob.alloc(width * height);
			status = bakeFontBitmap(blob, offset, bakedFontSize, pixels, width, height, glyphs, baked);
			if (status <= 0)
				height < width ? height *= 2 : width *= 2;
		}

		// TODO: Scale pixels down if they exceed the supported texture size

		var info = new Stbtt_fontinfo();
		StbTruetype.stbtt_InitFont(info, blob, offset);

		var metrics = StbTruetype.stbtt_GetFontVMetrics(info);
		var scale = StbTruetype.stbtt_ScaleForPixelHeight(info, bakedFontSize);
		var ascent = Math.round(metrics.ascent * scale / sdfOversample); // equals baseline
		var descent = Math.round(metrics.descent * scale / sdfOversample);
		var lineGap = Math.round(metrics.lineGap * scale / sdfOversample);

		atlas = new FontAtlas(Std.int(size), ascent, descent, lineGap, width, height, baked, pixels);
		atlases.set(index, atlas);

		return atlas;
	}

	function process() {}
}
