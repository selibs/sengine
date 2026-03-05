package s2d.elements;

import se.Texture;
import se.assets.FontAsset;
import s2d.Alignment;

using se.extensions.StringExt;

class Label extends DrawableElement {
	var fontAsset:FontAsset = new FontAsset();
	@readonly @alias var kravur:se.resource.Font = fontAsset.asset;

	@alias public var font:String = fontAsset.source;
	public var fontSize(default, set):Int = 32;

	public var text(default, set):String;
	public var textX(default, null):Float = 0.0;
	public var textY(default, null):Float = 0.0;
	public var textWidth(default, set):Float = 0.0;
	@alias public var textHeight:Int = fontSize;

	public var alignment:Alignment = AlignLeft | AlignTop;

	public function new(text:String = "") {
		super();
		this.text = text;
		color = Black;
		font = "font_default";
		fontAsset.onAssetLoaded(_ -> syncTextWidth());
	}

	function draw(target:Texture) {
		if (text != "" && kravur != null) {
			final ctx = target.context2D;
			ctx.style.font = kravur;
			ctx.style.fontSize = fontSize;
			ctx.style.color = color;
			ctx.drawString(text, textX, textY);
		}
	}

	function syncTextWidth() {
		if (kravur != null && text != "")
			textWidth = kravur.width(fontSize, text);
	}

	@:slot(absXChanged, widthChanged)
	function syncHAlignment(_:Float) {
		textX = absX;
		if ((alignment & AlignHCenter) != 0)
			textX += (width - textWidth) * 0.5;
		else if ((alignment & AlignRight) != 0)
			textX += width - textWidth;
	}

	@:slot(absYChanged, heightChanged)
	function syncVAlignment(_:Float) {
		textY = absY;
		if ((alignment & AlignVCenter) != 0)
			textY += (height - fontSize) * 0.5;
		else if ((alignment & AlignBottom) != 0)
			textY += height - fontSize;
	}

	function set_text(value:String):String {
		text = value;
		syncTextWidth();
		return text;
	}

	function set_fontSize(value:Int) {
		fontSize = value < 0 ? 0 : value;
		syncTextWidth();
		return value;
	}

	function set_textWidth(value:Float):Float {
		textWidth = value;
		syncHAlignment(0.0);
		return textWidth;
	}
}
