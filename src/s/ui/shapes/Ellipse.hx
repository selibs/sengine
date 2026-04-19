package s.ui.shapes;

@:allow(s.ui.graphics.shapes.EllipseDrawer)
class Ellipse extends Shape {
	function draw(target:s.graphics.RenderTarget) {
		s.ui.graphics.shapes.EllipseDrawer.shader.render(target, this);
	}
}
