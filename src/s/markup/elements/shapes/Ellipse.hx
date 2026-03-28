package s.markup.elements.shapes;

@:allow(s.markup.graphics.shapes.EllipseDrawer)
class Ellipse extends Shape {
	function draw(target:s.graphics.RenderTarget) {
		s.markup.graphics.shapes.EllipseDrawer.shader.render(target, this);
	}
}
