package s.ui.elements.gradients;

@:allow(s.ui.graphics.gradients.LinearGradientDrawer)
class LinearGradient extends Gradient {
	function draw(target:s.graphics.RenderTarget) {
		s.ui.graphics.gradients.LinearGradientDrawer.shader.render(target, this);
	}
}
