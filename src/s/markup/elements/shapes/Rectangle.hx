package s.markup.elements.shapes;

@:allow(s.markup.graphics.RectangleDrawer)
class Rectangle extends Shape {
	function draw(target:s.graphics.RenderTarget) {
		s.markup.graphics.shapes.RectangleDrawer.shader.render(target, this);
	}
}
