package s.ui.elements.shapes;

@:allow(s.ui.graphics.RectangleDrawer)
class Rectangle extends Shape {
	function draw(target:s.graphics.RenderTarget) {
		s.ui.graphics.shapes.RectangleDrawer.shader.render(target, this);
	}
}
