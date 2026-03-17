package s.markup.elements.shapes;

import s.system.Texture;
import s.markup.graphics.RectDrawer;

@:allow(s.markup.graphics.RectDrawer)
@:access(s.markup.graphics.RectDrawer)
class RectangleRounded extends ShapeRounded {
	function draw(target:Texture) {
		RectDrawer.shader.render(target, this);
	}
}
