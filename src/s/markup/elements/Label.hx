package s.markup.elements;

import s.graphics.Texture;
import s.geometry.Rect;
import s.markup.Alignment;
import s.markup.ElementFont.ElementFontChar;

using StringTools;

@:allow(s.markup.graphics.TextDrawer)
class Label extends DrawableElement {
	@:attr var chars:Array<ElementFontChar> = [];

	@:attr var textX:Float = 0.0;
	@:attr var textY:Float = 0.0;
	@:attr var textWidth:Float = 0.0;

	@:attr.group public var font(default, never):ElementFont = new ElementFont();

	@:attr public var text:String;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;
	@:attr public var elideMode:ElideMode = ElideNone;

	@:readonly @:alias public var displayX:Float = textX;
	@:readonly @:alias public var displayY:Float = textY;
	@:readonly @:alias public var displayWidth:Float = textWidth;
	@:readonly @:alias public var displayHeight:Float = font.pixelSize;

	public function new(text:String = "") {
		super();
		this.text = text;
	}

	function draw(target:Texture) {
		if (text.length == 0 || !font.font.isLoaded || font.pixelSize == 0)
			return;
		s.markup.graphics.TextDrawer.shader.render(target, this);
	}

	override function sync() {
		super.sync();
		if (text.length == 0 || !font.font.isLoaded || font.pixelSize == 0)
			return;
		syncText();
	}

	function syncText():Void {
		final hIsDirty = left.positionIsDirty || right.positionIsDirty || left.paddingIsDirty || right.paddingIsDirty;
		final vIsDirty = top.positionIsDirty || bottom.positionIsDirty || top.paddingIsDirty || bottom.paddingIsDirty;
		final charsAreDirty = textIsDirty || font.isDirty || elideMode != ElideNone && (elideModeIsDirty || hIsDirty);

		if (charsAreDirty) {
			chars = [];
			textWidth = elideLine(text);
		}

		if (textWidthIsDirty || font.pixelSizeIsDirty || hIsDirty || vIsDirty || alignmentIsDirty) {
			textX = alignLineX(textWidth);
			textY = alignLineY(font.pixelSize);
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
		final atlas = font.font.getAtlas(font.pixelSize);

		inline function copyChar(char:ElementFontChar):ElementFontChar
			return {
				xoff: char.xoff,
				yoff: char.yoff,
				advance: char.advance,
				pos: new Rect(char.pos.x, char.pos.y, char.pos.width, char.pos.height),
				uv: new Rect(char.uv.x, char.uv.y, char.uv.width, char.uv.height)
			}

		final ec = font.getElementChar(".".code);
		final ew = ec.advance * 3;

		var maxWidth = Math.max(0.0, Math.abs(width) - left.padding - right.padding);
		maxWidth -= ew;

		var w = 0.0;
		if (elideMode == ElideLeft) {
			for (i in 0...text.length) {
				var c = font.getElementChar(text.fastCodeAt(text.length - i - 1));
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
				var c = font.getElementChar(text.fastCodeAt(i));
				if (w + c.advance > maxWidth)
					break;
				chars.push(c);
				w += c.advance;
				var c = font.getElementChar(text.fastCodeAt(text.length - i - 1));
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
				var c = font.getElementChar(text.fastCodeAt(i));
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
				var c = font.getElementChar(text.fastCodeAt(i));
				chars.push(c);
				w += c.advance;
			}
		}
		return w;
	}
}
