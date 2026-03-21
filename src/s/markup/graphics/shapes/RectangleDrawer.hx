package s.markup.graphics.shapes;

import s.markup.elements.shapes.Rectangle;

@:allow(s.markup.elements.shapes.Rectangle)
class RectangleDrawer extends ShapeDrawer<Rectangle> {
	function new() {
		super("rectangle");
	}
}
