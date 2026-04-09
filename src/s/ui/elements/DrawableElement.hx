package s.ui.elements;

import s.graphics.RenderTarget;

abstract class DrawableElement extends Element {
	var realColor:Color = White;

	@:attr(visual) public var color:Color = White;

	abstract function draw(target:RenderTarget):Void;

	override function sync() {
		super.sync();

		if (visualDirty || globalOpacityDirty)
			realColor = Color.rgba(color.r, color.g, color.b, color.a * globalOpacity);

		if (globalVisible && scene.collectDrawables)
			scene.drawableScratch.push(this);
	}
}
