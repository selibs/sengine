package s.markup.elements.gradients;

@:allow(s.markup.graphics.gradients.ConicGradientDrawer)
class ConicGradient extends Gradient {
	public function new() {
		super();
		start = {x: 0.5, y: 0.5};
		end = {x: 1.0, y: 0.5};
	}

	function draw(target:s.graphics.RenderTarget) {
		s.markup.graphics.gradients.ConicGradientDrawer.shader.render(target, this);
	}
}
