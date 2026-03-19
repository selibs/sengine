package s.markup.elements;

import s.system.Texture;
import s.system.assets.FontAsset;
import s.markup.Alignment;

class Label extends DrawableElement {
	var fontAsset:FontAsset = new FontAsset();
	var textX:Float = 0.0;
	var textY:Float = 0.0;
	var textWidth:Float = 0.0;

	@:attr public var text:String;
	@:attr public var fontSize(default, set):Int = 14;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;

	@:alias public var font:String = fontAsset.source;

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

	override function sync(target:Texture) {
		if (text.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		super.sync(target);
		syncTextSize();
	}

	function syncTextSize() {
		final textWidthIsDirty = textIsDirty || fontSizeIsDirty;

		if (textWidthIsDirty)
			textWidth = fontAsset.asset.width(fontSize, text);

		final hIsDirty = alignmentIsDirty || textWidthIsDirty;
		final vIsDirty = alignmentIsDirty || fontSizeIsDirty;

		if ((alignment & AlignHCenter) != 0 && (hIsDirty || hCenter.positionIsDirty))
			textX = hCenter.position - textWidth * 0.5;
		else if ((alignment & AlignRight) != 0 && (hIsDirty || hCenter.positionIsDirty))
			textX = right.position - textWidth;
		else if (hIsDirty || left.positionIsDirty)
			textX = left.position;

		if ((alignment & AlignVCenter) != 0 && (vIsDirty || vCenter.positionIsDirty))
			textY = vCenter.position - fontSize * 0.5;
		else if ((alignment & AlignBottom) != 0 && (vIsDirty || vCenter.positionIsDirty))
			textY = bottom.position - fontSize;
		else if (vIsDirty || top.positionIsDirty)
			textY = top.position;
	}

	function set_fontSize(value:Int):Int
		return fontSize = value > 0 ? value : 0;
}
