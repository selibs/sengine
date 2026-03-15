package s2d.elements.shapes;

import se.Texture;
import s2d.graphics.RectDrawer;

@:allow(s2d.graphics.RectDrawer)
@:access(s2d.graphics.RectDrawer)
class RectangleRounded extends ShapeRounded {
	function draw(target:Texture) {
		RectDrawer.shader.render(target, this);
	}
}
