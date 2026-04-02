package s.ui.elements.shapes;

import s.math.Vec2;

@:allow(s.ui.graphics.shapes.TriangleDrawer)
class Triangle extends Shape {
	public var point1:Vec2 = {x: 0.0, y: 1.0};
	public var point2:Vec2 = {x: 0.5, y: 0.0};
	public var point3:Vec2 = {x: 1.0, y: 1.0};

	function draw(target:s.graphics.RenderTarget) {
		s.ui.graphics.shapes.TriangleDrawer.shader.render(target, this);
	}
}
