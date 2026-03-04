package s2d.elements.shapes;

import se.Texture;

@:ui.shortcut(rectangle)
class Rectangle extends Shape {
	public function new(name:String = "rectangle") {
		super(name);
	}

	function draw(target:Texture) {
		final ctx = target.context2D;
		ctx.fillRect(absX, absY, width, height);
		ctx.style.color = border.color;
		ctx.drawRect(absX, absY, width, height, border.width);
	}
}
