package s.markup.elements;

import s.math.Mat3;

@:dox(hide)
@:allow(s.markup.graphics.ElementDrawer)
abstract class DrawableElement extends Element {
	@:attr public var color:Color = White;

	abstract function draw(target:Texture):Void;

	override function render(target:Texture) {
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		var i = 0;
		while (i < children.length && children[i].z < 0.0)
			Element.renderElement(children[i++], target);
		draw(target);
		while (i < children.length)
			Element.renderElement(children[i++], target);
		ctx.style.popOpacity();
	}
}
