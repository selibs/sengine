package s.ui.elements;

import s.ui.Element;
import s.graphics.RenderTarget;

typedef DrawableAttributes = {
	> ElementAttributes,
	?color:Color
}

@:allow(s.ui.Scene)
abstract class Drawable extends Element {
	public static inline function setAttributes(x:Drawable, a:DrawableAttributes) {
		Element.setAttributes(x, a);
		if (a.color != null)
			x.color = a.color;
	}

	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	override function update() {
		super.update();

		if (visualDirty || globalOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * globalOpacity);

		updateOrder();
	}

	function updateOrder()
		if (globalVisible && layer.children.dirty)
			layer.drawable.push(this);
}
