package s.markup.elements;

import s.system.Color;
import s.system.Texture;

abstract class DrawableElement extends Element {
	@:signal public var color:Color = White;

	abstract function draw(target:Texture):Void;

	override function render(target:Texture) {
		sync();
		flush();

		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		var i = 0;
		while (i < children.length && children[i].z < 0.0) {
			Element.renderElement(target, children[i]);
			i++;
		}
		draw(target);
		while (i < children.length) {
			Element.renderElement(target, children[i]);
			i++;
		}
		ctx.style.popOpacity();
	}
}
