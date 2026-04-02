package s.ui.elements.gradients;

@:allow(s.ui.graphics.gradients.RadialGradientDrawer)
class RadialGradient extends Gradient {
	public function new() {
		super();
		start = {x: 0.5, y: 0.5};
		end = {x: 1.0, y: 0.5};
	}

	function draw(target:s.graphics.RenderTarget) {
		s.ui.graphics.gradients.RadialGradientDrawer.shader.render(target, this);
	}
}
