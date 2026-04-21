package s.ui.elements;

import s.graphics.RenderTarget;

@:allow(s.ui.Scene)
abstract class Drawable extends Element {
	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	override function update() {
		super.update();

		updateRealColor();
		updateOrder();
	}

	function updateRealColor() {
		if (visualDirty || globalOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * globalOpacity);
	}

	function updateOrder() {
		if (globalVisible && layer.children.dirty)
			layer.drawable.push(this);
	}
}
