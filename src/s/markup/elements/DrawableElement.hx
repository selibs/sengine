package s.markup.elements;

import s.Color;
import s.Texture;
import s.math.Vec2;
import s.markup.elements.ElementPoint;

abstract class DrawableElement extends Element {
	private static inline function syncPoint(element:DrawableElement, target:Texture, rp:Vec2, p:ElementPoint, pIsDirty:Bool) {
		p.x.self.resolve(element.width.real, target.width, target.height);
		p.y.self.resolve(element.height.real, target.width, target.height);
		if (pIsDirty || p.xIsDirty || p.x.realIsDirty)
			rp.x = element.left.position + p.x.real;
		if (pIsDirty || p.yIsDirty || p.y.realIsDirty)
			rp.y = element.top.position + p.y.real;
	}

	private static inline function syncPointNormalize(element:DrawableElement, target:Texture, rp:Vec2, p:ElementPoint, pIsDirty:Bool) {
		p.x.self.resolve(element.width.real, target.width, target.height);
		p.y.self.resolve(element.height.real, target.width, target.height);
		if (pIsDirty || p.xIsDirty || p.x.realIsDirty)
			rp.x = p.x.real / element.width.real;
		if (pIsDirty || p.yIsDirty || p.y.realIsDirty)
			rp.y = p.y.real / element.height.real;
	}

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
