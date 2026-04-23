package s.ui.elements;

import s.ui.Element;
import s.graphics.RenderTarget;

@:allow(s.ui.Scene)
abstract class Drawable extends Element {
	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	override function update() {
		super.update();

		if (visualDirty || realOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * realOpacity);

		updateOrder();
	}

	function updateOrder()
		if (realVisible && layer.children.dirty)
			layer.drawable.push(this);
}
