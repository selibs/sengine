package s.ui.elements;

import s.graphics.RenderTarget;

abstract class DrawableElement extends Element {
	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	@:slot(sync)
	function syncRealColor(_)
		if (visualDirty || globalOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * globalOpacity);

	@:slot(sync)
	function syncOrder(_)
		if (globalVisible && scene.root.children.dirty)
			scene.drawable.push(this);
}
