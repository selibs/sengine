package s.markup.elements;

import haxe.ds.IntMap;
import s.Texture;
import s.assets.FontAsset;
import s.markup.Alignment;
import s.markup.geometry.Rect;

using StringTools;

@:allow(s.markup.graphics.TextDrawer)
class Label extends DrawableElement {
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

	var fontAsset:FontAsset = new FontAsset();
	@:attr var chars:Array<{
		xoff:Float,
		yoff:Float,
		advance:Float,
		pos:Rect,
		uv:Rect
	}> = [];
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
			elideLine(text);
		}

		if (textWidthIsDirty || fontSizeIsDirty || hIsDirty || vIsDirty || alignmentIsDirty) {
			if (alignment & AlignRight != 0)
				textX = right.position - right.padding - textWidth;
			else if (alignment & AlignHCenter != 0)
				textX = hCenter.position - textWidth * 0.5;
			else
				textX = left.position + left.padding;

			if (alignment & AlignBottom != 0)
				textY = bottom.position - bottom.padding - fontSize;
			else if (alignment & AlignVCenter != 0)
				textY = vCenter.position - fontSize * 0.5;
			else
				textY = top.position + top.padding;
		}

		if (charsAreDirty || textXIsDirty) {
			var offset = textX;
			for (c in chars) {
				c.pos.x = offset + c.xoff;
				offset += c.advance;
			}
		}
		if (charsAreDirty || textYIsDirty)
			for (c in chars)
				c.pos.y = textY + c.yoff;
	}

	function elideLine(line:String) {
		final atlas = fontAsset.asset._get(fontSize);

		function getChar(index:Int):{
			xoff:Float,
			yoff:Float,
			advance:Float,
			pos:Rect,
			uv:Rect
		} {
			var g = getGlyph(atlas, index);
			var w:Float = g.x1 - g.x0;
			var h:Float = g.y1 - g.y0;
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
					width: w / atlas.width,
					height: h / atlas.height
				}
			}
		}

		final ec = getChar(".".code);
		final ew = ec.advance * 3;

		var maxWidth = Math.max(0.0, Math.abs(width) - left.padding - right.padding);
		maxWidth -= ew;

		if (elideMode == ElideLeft) {
			var w = 0.0;
			var i = text.length - 1;
			while (i >= 0) {
				var c = getChar(text.fastCodeAt(i--));
				if (w + c.advance > maxWidth)
					break;
				chars.unshift(c);
				w += c.advance;
			}
			// ellipsis
			chars.unshift(ec);
			chars.unshift(ec);
			chars.unshift(ec);
			textWidth = w + ew;
		} else if (elideMode == ElideMiddle) {} else if (elideMode == ElideRight) {
			var w = 0.0;
			var i = 0;
			while (i < text.length) {
				var c = getChar(text.fastCodeAt(i++));
				if (w + c.advance > maxWidth)
					break;
				chars.push(c);
				w += c.advance;
			}
			// ellipsis
			chars.push(ec);
			chars.push(ec);
			chars.push(ec);
			textWidth = w + ew;
		} else {
			var w = 0.0;
			for (i in 0...text.length) {
				var c = getChar(text.fastCodeAt(i));
				chars.push(c);
				w += c.advance;
			}
			textWidth = w;
		}
	}

	function set_fontSize(value:Int):Int
		return fontSize = value > 0 ? value : 0;
}
