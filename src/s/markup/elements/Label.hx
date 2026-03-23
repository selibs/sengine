package s.markup.elements;

import kha.Blob;
import kha.graphics2.truetype.StbTruetype;
import haxe.ds.Vector;
import kha.Kravur.KravurImage;
import s.resource.Font;
import s.text.FontGlyph;
import haxe.ds.IntMap;
import s.Texture;
import s.assets.FontAsset;
import s.markup.Alignment;
import s.geometry.Rect;

using StringTools;

@:allow(s.markup.graphics.TextDrawer)
class Label extends DrawableElement {
	static inline final sdfOversample:Int = 4;
	static inline final sdfSpread:Int = 8;
	static inline final sdfPadding:Int = sdfSpread + 1;
	static inline final sdfInf:Float = 1e20;

	static function getGlyph(atlas:kha.Kravur.KravurImage, charCode:Int):kha.graphics2.truetype.StbTruetype.Stbtt_bakedchar {
		static var charIndices:IntMap<Int> = new IntMap();

		var ind = charIndices.get(charCode);
		if (ind == null) {
			var blocks = kha.Kravur.KravurImage.charBlocks;
			var offset = 0;

			for (i in 0...Std.int(blocks.length / 2)) {
				var start = blocks[i * 2];
				var end = blocks[i * 2 + 1];
				if (charCode >= start && charCode <= end) {
					ind = offset + charCode - start;
					break;
				}
				offset += end - start + 1;
			}

			ind = ind ?? 0;
			charIndices.set(charCode, ind);
		}

		return @:privateAccess atlas.chars[ind];
	}

	static function getAtlas(font:Font, fontSize:Int) @:privateAccess {
		final bakedFontSize = fontSize * sdfOversample;
		var glyphs = kha.graphics2.Graphics.fontGlyphs;

		if (glyphs != font.oldGlyphs) {
			font.oldGlyphs = glyphs;
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

		var imageIndex = font.fontIndex * 10000000 + bakedFontSize * 10000 + glyphs.length;
		if (!font.images.exists(imageIndex)) {
			var offset = StbTruetype.stbtt_GetFontOffsetForIndex(font.blob, font.fontIndex);
			if (offset == -1) {
				offset = StbTruetype.stbtt_GetFontOffsetForIndex(font.blob, 0);
			}
			var atlasSize = estimateAtlasSize(font.blob, offset, bakedFontSize, glyphs);
			var width:Int = atlasSize.width;
			var height:Int = atlasSize.height;
			var baked = new Vector<Stbtt_bakedchar>(glyphs.length);
			for (i in 0...baked.length) {
				baked[i] = new Stbtt_bakedchar();
			}

			var pixels:Blob = null;
			var status:Int = -1;
			while (status <= 0) {
				pixels = Blob.alloc(width * height);
				status = bakeFontBitmap(font.blob, offset, bakedFontSize, pixels, width, height, glyphs, baked);
				if (status <= 0) {
					if (height < width)
						height *= 2;
					else
						width *= 2;
				}
			}

			// TODO: Scale pixels down if they exceed the supported texture size

			var info = new Stbtt_fontinfo();
			StbTruetype.stbtt_InitFont(info, font.blob, offset);

			var metrics = StbTruetype.stbtt_GetFontVMetrics(info);
			var scale = StbTruetype.stbtt_ScaleForPixelHeight(info, bakedFontSize);
			var ascent = Math.round(metrics.ascent * scale / sdfOversample); // equals baseline
			var descent = Math.round(metrics.descent * scale / sdfOversample);
			var lineGap = Math.round(metrics.lineGap * scale / sdfOversample);

			var image = new KravurImage(Std.int(fontSize), ascent, descent, lineGap, width, height, baked, pixels);
			font.images[imageIndex] = image;
			return image;
		}
		return font.images[imageIndex];
	}

	static function bakeFontBitmap(data:Blob, offset:Int, // font location (use offset=0 for plain .ttf)
		pixel_height:Float, // height of font in pixels
			pixels:Blob, pw:Int, ph:Int, // bitmap to be filled in
		chars:Array<Int>, // characters to bake
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

	static inline function edtIntersection(f:Vector<Float>, q:Int, v:Int):Float {
		return ((f[q] + q * q) - (f[v] + v * v)) / (2.0 * (q - v));
	}

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

	var fontAsset:FontAsset = new FontAsset();
	@:attr var chars:Array<FontGlyph> = [];
	@:attr var textX:Float = 0.0;
	@:attr var textY:Float = 0.0;
	@:attr var textWidth:Float = 0.0;

	@:attr public var text:String;
	@:attr public var fontSize(default, set):Int = 14;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;
	@:attr public var elideMode:ElideMode = ElideNone;

	@:alias public var font:String = fontAsset.source;

	@:readonly @:alias public var displayX:Float = textX;
	@:readonly @:alias public var displayY:Float = textY;
	@:readonly @:alias public var displayWidth:Float = textWidth;
	@:readonly @:alias public var displayHeight:Float = fontSize;

	public function new(text:String = "") {
		super();
		this.text = text;
		font = "font_default";
		fontAsset.onAssetLoaded(_ -> textIsDirty = true);
	}

	function draw(target:Texture) {
		if (text.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		s.markup.graphics.TextDrawer.shader.render(target, this);
	}

	override function sync() {
		super.sync();
		if (text.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		syncText();
	}

	function syncText():Void {
		final hIsDirty = left.positionIsDirty || right.positionIsDirty || left.paddingIsDirty || right.paddingIsDirty;
		final vIsDirty = top.positionIsDirty || bottom.positionIsDirty || top.paddingIsDirty || bottom.paddingIsDirty;
		final charsAreDirty = textIsDirty || fontSizeIsDirty || elideMode != ElideNone && (elideModeIsDirty || hIsDirty);

		if (charsAreDirty) {
			chars = [];
			textWidth = elideLine(text);
		}

		if (textWidthIsDirty || fontSizeIsDirty || hIsDirty || vIsDirty || alignmentIsDirty) {
			textX = alignLineX(textWidth);
			textY = alignLineY(fontSize);
		}

		if (charsAreDirty || textXIsDirty)
			alignCharsX(textX);
		if (charsAreDirty || textYIsDirty)
			alignCharsY(textY);
	}

	function alignCharsX(offset:Float) {
		for (c in chars) {
			c.pos.x = offset + c.xoff;
			offset += c.advance;
		}
	}

	function alignCharsY(offset:Float) {
		for (c in chars)
			c.pos.y = offset + c.yoff;
	}

	function alignLineX(width:Float) {
		if (alignment & AlignRight != 0)
			return right.position - right.padding - width;
		else if (alignment & AlignHCenter != 0)
			return hCenter.position - width * 0.5;
		else
			return left.position + left.padding;
	}

	function alignLineY(height:Float) {
		if (alignment & AlignBottom != 0)
			return bottom.position - bottom.padding - height;
		else if (alignment & AlignVCenter != 0)
			return vCenter.position - height * 0.5;
		else
			return top.position + top.padding;
	}

	function elideLine(line:String):Float {
		final atlas = getAtlas(fontAsset.asset, fontSize);

		inline function getChar(index:Int):FontGlyph {
			var g = getGlyph(atlas, index);
			var atlasW:Float = g.x1 - g.x0;
			var atlasH:Float = g.y1 - g.y0;
			var w:Float = atlasW / sdfOversample;
			var h:Float = atlasH / sdfOversample;
			return {
				xoff: g.xoff,
				yoff: g.yoff,
				advance: g.xadvance,
				pos: {
					x: 0.0,
					y: 0.0,
					width: w,
					height: h
				},
				uv: {
					x: g.x0 / atlas.width,
					y: g.y0 / atlas.height,
					width: atlasW / atlas.width,
					height: atlasH / atlas.height
				}
			}
		}

		inline function copyChar(char:FontGlyph):FontGlyph
			return {
				xoff: char.xoff,
				yoff: char.yoff,
				advance: char.advance,
				pos: new Rect(char.pos.x, char.pos.y, char.pos.width, char.pos.height),
				uv: new Rect(char.uv.x, char.uv.y, char.uv.width, char.uv.height)
			}

		final ec = getChar(".".code);
		final ew = ec.advance * 3;

		var maxWidth = Math.max(0.0, Math.abs(width) - left.padding - right.padding);
		maxWidth -= ew;

		var w = 0.0;
		if (elideMode == ElideLeft) {
			for (i in 0...text.length) {
				var c = getChar(text.fastCodeAt(text.length - i - 1));
				if (w + c.advance > maxWidth)
					break;
				chars.unshift(c);
				w += c.advance;
			}
			// ellipsis
			chars.unshift(copyChar(ec));
			chars.unshift(copyChar(ec));
			chars.unshift(copyChar(ec));
			w += ew;
		} else if (elideMode == ElideMiddle) {
			var r = [];
			for (i in 0...text.length) {
				var c = getChar(text.fastCodeAt(i));
				if (w + c.advance > maxWidth)
					break;
				chars.push(c);
				w += c.advance;
				var c = getChar(text.fastCodeAt(text.length - i - 1));
				if (w + c.advance > maxWidth)
					break;
				r.unshift(c);
				w += c.advance;
			}
			// ellipsis
			chars.push(copyChar(ec));
			chars.push(copyChar(ec));
			chars.push(copyChar(ec));
			w += ew;
			chars = chars.concat(r);
		} else if (elideMode == ElideRight) {
			for (i in 0...text.length) {
				var c = getChar(text.fastCodeAt(i));
				if (w + c.advance > maxWidth)
					break;
				chars.push(c);
				w += c.advance;
			}
			// ellipsis
			chars.push(copyChar(ec));
			chars.push(copyChar(ec));
			chars.push(copyChar(ec));
			w += ew;
		} else {
			for (i in 0...text.length) {
				var c = getChar(text.fastCodeAt(i));
				chars.push(c);
				w += c.advance;
			}
		}
		return w;
	}

	function set_fontSize(value:Int):Int
		return fontSize = value > 0 ? value : 0;
}
