package s.markup.elements.shapes;

import s.system.Texture;

class Rectangle extends Shape {
	function draw(target:Texture) {
		final ctx = target.context2D;
		ctx.style.color = color;
		ctx.fillRect(left.position, top.position, width.real, height.real);
		ctx.style.color = border.color;
		ctx.drawRect(left.position, top.position, width.real, height.real, border.width);
	}
}
