package s.ui.elements;

import s.geometry.Rect;
import s.ui.Alignment;
import s.graphics.FontStyle;

using StringTools;

@:allow(s.ui.graphics.TextDrawer)
@:access(s.graphics.FontStyle)
class Label extends DrawableElement {
	var chars:Array<FontChar> = [];

	@:attr var textX:Float = 0.0;
	@:attr var textY:Float = 0.0;
	@:attr var textWidth:Float = 0.0;

	@:attr.group public var font(default, never):FontStyle = new FontStyle();

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

	function draw(target:s.graphics.RenderTarget) {
		if (text.length == 0 || !font.isLoaded || font.pixelSize == 0)
			return;
		var ctx = target.context2D;
		var prevFont = ctx.style.font;
		var prevColor = ctx.style.color;
		ctx.style.font = font;
		ctx.style.color = color;
		ctx.drawFontChars(chars);
		ctx.style.color = prevColor;
		ctx.style.font = prevFont;
	}

	override function sync() {
		super.sync();
		if (text.length == 0 || !font.isLoaded || font.pixelSize == 0)
			return;
		syncText();
	}

	function syncText():Void {
		final hIsDirty = left.positionIsDirty || right.positionIsDirty || left.paddingIsDirty || right.paddingIsDirty;
		final vIsDirty = top.positionIsDirty || bottom.positionIsDirty || top.paddingIsDirty || bottom.paddingIsDirty;
		final charsAreDirty = textIsDirty || font.isDirty || elideMode != ElideNone && (elideModeIsDirty || hIsDirty);

		if (charsAreDirty) {
			chars = [];
			var lineChars = [];
			var lineWidth = 0.0;
			for (i in 0...text.length) {
				var c = font.getFontChar(text.fastCodeAt(i));
				lineChars.push(c);
				lineWidth += c.advance;
			}
			textWidth = elideLineChars(lineChars, lineWidth);
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
		final snap = font.snapToPixel;
		for (c in chars)
			c.pos.y = offset + (snap ? Math.round(c.yoff) : c.yoff);
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

	function elideLineChars(lineChars:Array<FontChar>, lineWidth:Float):Float {
		inline function copyChar(char:FontChar):FontChar
			return {
				xoff: char.xoff,
				yoff: char.yoff,
				advance: char.advance,
				pos: {
					x: char.pos.x,
					y: char.pos.y,
					width: char.pos.width,
					height: char.pos.height
				},
				uv: {
					x: char.uv.x,
					y: char.uv.y,
					width: char.uv.width,
					height: char.uv.height
				}
			}

		final ec = font.getFontChar(".".code);
		final ew = ec.advance * 3;
		final availableWidth = Math.max(0.0, Math.abs(width) - left.padding - right.padding);

		if (elideMode == ElideNone || lineWidth <= availableWidth) {
			chars = lineChars;
			return lineWidth;
		}

		var maxWidth = Math.max(0.0, availableWidth - ew);

		var w = 0.0;
		var e = false;
		if (elideMode == ElideLeft) {
			for (i in 0...lineChars.length) {
				var c = lineChars[lineChars.length - i - 1];
				if (w + c.advance > maxWidth) {
					e = true;
					break;
				}
				chars.unshift(c);
				w += c.advance;
			}
			// ellipsis
			if (e) {
				chars.unshift(copyChar(ec));
				chars.unshift(copyChar(ec));
				chars.unshift(copyChar(ec));
				w += ew;
			}
		} else if (elideMode == ElideMiddle) {
			var r = [];
			var leftIndex = 0;
			var rightIndex = lineChars.length - 1;
			while (leftIndex <= rightIndex) {
				var leftChar = lineChars[leftIndex];
				if (w + leftChar.advance > maxWidth) {
					e = true;
					break;
				}
				chars.push(leftChar);
				w += leftChar.advance;
				leftIndex++;

				if (leftIndex > rightIndex)
					break;

				var rightChar = lineChars[rightIndex];
				if (w + rightChar.advance > maxWidth) {
					e = true;
					break;
				}
				r.unshift(rightChar);
				w += rightChar.advance;
				rightIndex--;
			}
			// ellipsis
			if (e) {
				chars.push(copyChar(ec));
				chars.push(copyChar(ec));
				chars.push(copyChar(ec));
				w += ew;
			}
			chars = chars.concat(r);
		} else if (elideMode == ElideRight) {
			for (i in 0...lineChars.length) {
				var c = lineChars[i];
				if (w + c.advance > maxWidth) {
					e = true;
					break;
				}
				chars.push(c);
				w += c.advance;
			}
			// ellipsis
			if (e) {
				chars.push(copyChar(ec));
				chars.push(copyChar(ec));
				chars.push(copyChar(ec));
				w += ew;
			}
		} else {
			for (i in 0...text.length) {
				var c = font.getFontChar(text.fastCodeAt(i));
				chars.push(c);
				w += c.advance;
			}
		}

		return w;
	}
}
