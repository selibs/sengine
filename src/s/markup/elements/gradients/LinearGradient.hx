package s.markup.elements.gradients;

@:allow(s.markup.graphics.gradients.LinearGradientDrawer)
class LinearGradient extends Gradient {
	function draw(target:Texture) {
		s.markup.graphics.gradients.LinearGradientDrawer.shader.render(target, this);
	}
}
