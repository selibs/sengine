package s.markup.elements.shapes;

import s.Texture;

@:allow(s.markup.graphics.shapes.EllipseDrawer)
class Ellipse extends Circle {
	@:attr public var scaleX:Float = 1.0;
	@:attr public var scaleY:Float = 1.0;

	override function draw(target:s.Texture) {
		s.markup.graphics.shapes.EllipseDrawer.shader.render(target, this);
	}
}
