package s.markup.elements;

import s.Texture;
import s.assets.FontAsset;
import s.markup.Alignment;

class Label extends DrawableElement {
	var fontAsset:FontAsset = new FontAsset();
	@:attr var textX:Float = 0.0;
	@:attr var textY:Float = 0.0;
	@:attr var textWidth:Float = 0.0;
	@:attr var textHeight:Float = 0.0;

	@:attr public var text:String;
	@:attr public var fontSize(default, set):Int = 14;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;

	@:alias public var font:String = fontAsset.source;

	@:readonly @:alias public var contentX:Float = textX;
	@:readonly @:alias public var contentY:Float = textY;
	@:readonly @:alias public var contentWidth:Float = textWidth;
	@:readonly @:alias public var contentHeight:Float = textHeight;

	public function new(text:String = "") {
		super();
		this.text = text;
		font = "font_default";
		fontAsset.onAssetLoaded(_ -> textIsDirty = true);
	}

	function draw(target:Texture) {
		if (text.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		final ctx = target.context2D;
		ctx.style.font = fontAsset;
		ctx.style.fontSize = fontSize;
		ctx.style.color = color;
		ctx.drawString(text, textX, textY);
	}

	override function sync() {
		super.sync();
		syncText();
	}

	function syncText() {
		if (textIsDirty || fontSizeIsDirty)
			textWidth = fontAsset.asset.width(fontSize, text);
		if (fontSizeIsDirty)
			textHeight = fontSize;

		final hIsDirty = alignmentIsDirty || textWidthIsDirty;
		final vIsDirty = alignmentIsDirty || fontSizeIsDirty;

		if ((hIsDirty || hCenter.positionIsDirty) && (alignment & AlignHCenter) != 0)
			textX = hCenter.position - textWidth * 0.5;
		else if ((hIsDirty || right.positionIsDirty) && (alignment & AlignRight) != 0)
			textX = right.position - textWidth;
		else if (hIsDirty || left.positionIsDirty)
			textX = left.position;

		if ((vIsDirty || vCenter.positionIsDirty) && (alignment & AlignVCenter) != 0)
			textY = vCenter.position - textHeight * 0.5;
		else if ((vIsDirty || bottom.positionIsDirty) && (alignment & AlignBottom) != 0)
			textY = bottom.position - textHeight;
		else if (vIsDirty || top.positionIsDirty)
			textY = top.position;
	}

	function set_fontSize(value:Int):Int
		return fontSize = value > 0 ? value : 0;
}
