package s.ui.gradients;

import s.ui.gradients.Gradient.GradientStops;

@:allow(s.ui.graphics.gradients.ConicGradientDrawer)
class ConicGradient extends Gradient {
	public function new(?stops:GradientStops) {
		super(stops);
		start = {x: 0.5, y: 0.5};
		end = {x: 1.0, y: 0.5};
	}

	function draw(target:s.graphics.RenderTarget)
		s.ui.graphics.gradients.ConicGradientDrawer.shader.render(target, this);
}
