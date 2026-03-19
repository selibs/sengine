package s.markup.elements;

import s.system.Texture;
import s.system.assets.FontAsset;
import s.markup.Alignment;

enum ElideMode {
	None;
	Left;
	Middle;
	Right;
}

enum WrapMode {
	NoWrap;
	WordWrap;
	WrapAnywhere;
	Wrap;
}

class Text extends Label {
	var lines:Array<{
		text:String,
		width:Float,
		x:Float,
		y:Float
	}> = [];

	@:attr public var wrap:WrapMode = NoWrap;
	@:attr public var elide:ElideMode = None;

	public function new(text:String = "") {
		super(text);
	}

	override function draw(target:Texture) {
		if (text.length == 0 || !fontAsset.isLoaded)
			return;
		final ctx = target.context2D;
		ctx.style.font = fontAsset;
		ctx.style.fontSize = fontSize;
		ctx.style.color = color;
		for (line in lines)
			ctx.drawString(line.text, line.x, line.y);
	}

	// TODO
	override function syncTextSize() {
		if (textIsDirty)
			lines = text.split("\n").map(t -> {
				text: t,
				x: 0.0,
				y: 0.0,
				width: fontAsset.asset.width(fontSize, t)
			});

		var d = 0.0;
		for (line in lines) {
			if ((alignment & AlignHCenter) != 0)
				line.x = hCenter.position - line.width * 0.5;
			else if ((alignment & AlignRight) != 0)
				line.x = right.position - line.width;
			else
				line.x = left.position;

			if ((alignment & AlignVCenter) != 0)
				line.y = vCenter.position - fontSize * 0.5 + d;
			else if ((alignment & AlignBottom) != 0)
				line.y = bottom.position - fontSize + d;
			else
				line.y = top.position;

			d += fontSize;
		}
	}
}
