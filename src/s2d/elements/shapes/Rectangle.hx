package s2d.elements.shapes;

import se.Texture;

class Rectangle extends Shape {
	function draw(target:Texture) {
		final ctx = target.context2D;
		ctx.style.color = color;
		ctx.fillRect(absX, absY, width, height);
		ctx.style.color = border.color;
		ctx.drawRect(absX, absY, width, height, border.width);
	}
}
