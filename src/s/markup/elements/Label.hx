package s.markup.elements;

import s.Texture;
import s.assets.FontAsset;
import s.markup.Alignment;

@:allow(s.markup.graphics.TextDrawer)
class Label extends DrawableElement {
	var fontAsset:FontAsset = new FontAsset();
	@:attr var textX:Float = 0.0;
	@:attr var textY:Float = 0.0;
	@:attr var textWidth:Float = 0.0;
	@:attr var textHeight:Float = 0.0;

	@:attr public var text:String;
	@:attr public var fontSize(default, set):Int = 14;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;
	@:attr public var elideMode:ElideMode = ElideNone;

	@:alias public var font:String = fontAsset.source;

	public var displayText(default, null):String = "";
	@:readonly @:alias public var displayX:Float = textX;
	@:readonly @:alias public var displayY:Float = textY;
	@:readonly @:alias public var displayWidth:Float = textWidth;
	@:readonly @:alias public var displayHeight:Float = textHeight;

	public function new(text:String = "") {
		super();
		this.text = text;
		font = "font_default";
		fontAsset.onAssetLoaded(_ -> textIsDirty = true);
	}

	function draw(target:Texture) {
		if (displayText.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		s.markup.graphics.TextDrawer.shader.render(target, this);
	}

	override function sync() {
		super.sync();
		syncText();
	}

	function syncText() {
		if (!fontAsset.isLoaded)
			return;

		final hBoundsIsDirty = left.positionIsDirty || left.paddingIsDirty || right.positionIsDirty || right.paddingIsDirty;
		final contentWidthIsDirty = widthIsDirty || hBoundsIsDirty;
		final textLayoutIsDirty = textIsDirty || fontSizeIsDirty || elideModeIsDirty || elideMode != ElideNone && contentWidthIsDirty;

		if (textLayoutIsDirty) {
			var line:TextLine = {
				text: text,
				width: fontAsset.asset.width(fontSize, text)
			};
			if (elideMode != ElideNone)
				elideLine(line);
			displayText = line.text;
			textWidth = line.width;
		}
		if (fontSizeIsDirty)
			textHeight = fontSize;

		final contentLeft = left.position + left.padding;
		final contentRight = right.position - right.padding;
		final contentTop = top.position + top.padding;
		final contentBottom = bottom.position - bottom.padding;

		final hIsDirty = alignmentIsDirty || textWidthIsDirty || hBoundsIsDirty;
		final vIsDirty = alignmentIsDirty || textHeightIsDirty || top.positionIsDirty || top.paddingIsDirty || bottom.positionIsDirty || bottom.paddingIsDirty;

		if (hIsDirty && (alignment & AlignHCenter) != 0)
			textX = (contentLeft + contentRight) * 0.5 - textWidth * 0.5;
		else if (hIsDirty && (alignment & AlignRight) != 0)
			textX = contentRight - textWidth;
		else if (hIsDirty)
			textX = contentLeft;

		if (vIsDirty && (alignment & AlignVCenter) != 0)
			textY = (contentTop + contentBottom) * 0.5 - textHeight * 0.5;
		else if (vIsDirty && (alignment & AlignBottom) != 0)
			textY = contentBottom - textHeight;
		else if (vIsDirty)
			textY = contentTop;
	}

	function elideLine(line:TextLine, forceEllipsis:Bool = false):Bool {
		static final ellipsis = "...";

		final k = fontAsset.asset._get(fontSize);
		final ellipsisWidth = k.stringWidth(ellipsis);
		final totalWidth = Math.max(0.0, Math.abs(width) - left.padding - right.padding);

		inline function charWidth(c:Int):Float
			return @:privateAccess k.getCharWidth(c);

		if (!forceEllipsis && line.width <= totalWidth)
			return false;

		if (totalWidth <= ellipsisWidth || line.text.length == 0) {
			line.text = ellipsis;
			line.width = ellipsisWidth;
			return true;
		}

		final maxWidth = totalWidth - ellipsisWidth;

		if (elideMode == ElideLeft) {
			var body = "";
			var bodyWidth = 0.0;
			var i = line.text.length - 1;
			while (i >= 0) {
				var c = line.text.charCodeAt(i);
				var cw = charWidth(c);
				if (bodyWidth + cw > maxWidth)
					break;
				body = line.text.charAt(i) + body;
				bodyWidth += cw;
				i--;
			}
			line.text = ellipsis + body;
			line.width = ellipsisWidth + bodyWidth;
		} else if (elideMode == ElideMiddle) {
			var left = new StringBuf();
			var right = "";
			var leftWidth = 0.0;
			var rightWidth = 0.0;
			var leftIndex = 0;
			var rightIndex = line.text.length - 1;
			var takeLeft = true;

			while (leftIndex <= rightIndex) {
				var index = takeLeft ? leftIndex : rightIndex;
				var c = line.text.charCodeAt(index);
				var cw = charWidth(c);
				if (leftWidth + rightWidth + cw > maxWidth)
					break;
				if (takeLeft) {
					left.addChar(c);
					leftWidth += cw;
					leftIndex++;
				} else {
					right = line.text.charAt(index) + right;
					rightWidth += cw;
					rightIndex--;
				}
				takeLeft = !takeLeft;
			}

			line.text = left.toString() + ellipsis + right;
			line.width = leftWidth + ellipsisWidth + rightWidth;
		} else if (elideMode == ElideRight) {
			var body = new StringBuf();
			var bodyWidth = 0.0;
			var i = 0;
			while (i < line.text.length) {
				var c = line.text.charCodeAt(i);
				var cw = charWidth(c);
				if (bodyWidth + cw > maxWidth)
					break;
				body.addChar(c);
				bodyWidth += cw;
				i++;
			}
			line.text = body.toString() + ellipsis;
			line.width = bodyWidth + ellipsisWidth;
		}

		return true;
	}

	function set_fontSize(value:Int):Int
		return fontSize = value > 0 ? value : 0;
}
