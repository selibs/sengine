package s.markup.graphics.shapes;

import s.markup.elements.shapes.Ellipse;

@:allow(s.markup.elements.shapes.Ellipse)
class EllipseDrawer extends ShapeDrawer<Ellipse> {
	function new() {
		super("ellipse");
	}
}
