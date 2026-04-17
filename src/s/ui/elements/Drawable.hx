package s.ui.elements;

import s.graphics.RenderTarget;

@:allow(s.ui.Scene)
abstract class Drawable extends Element {
	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	@:slot(update)
	function updateRealColor(_)
		if (visualDirty || globalOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * globalOpacity);

	@:slot(update)
	function updateOrder(_)
		if (globalVisible && scene.children.dirty)
			scene.drawable.push(this);
}
