package s2d;

import se.Color;
import se.Texture;

abstract class DrawableElement extends Element {
	@track public var color:Color = White;

	abstract function draw(target:Texture):Void;

	override function render(target:Texture) {
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		if (clip)
			ctx.scissor(Std.int(absX), Std.int(absY), Std.int(width), Std.int(height));
		var order = zsorted();
		for (c in order.below)
			if (c.visible)
				c.render(target);
		ctx.transform = globalTransform;
		ctx.style.color = color;
		draw(target);
		for (c in order.above)
			if (c.visible)
				c.render(target);
		if (clip)
			ctx.disableScissor();
		ctx.style.popOpacity();
	}
}
