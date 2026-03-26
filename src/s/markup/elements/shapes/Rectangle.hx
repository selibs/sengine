package s.markup.elements.shapes;

@:allow(s.markup.graphics.RectangleDrawer)
class Rectangle extends Shape {
	function draw(target:s.graphics.Texture) {
		s.markup.graphics.shapes.RectangleDrawer.shader.render(target, this);
	}
}
