package s.ui.gradients;

import s.ui.gradients.Gradient.GradientStops;

@:allow(s.ui.graphics.gradients.LinearGradientDrawer)
class LinearGradient extends Gradient {
	public function new(?stops:GradientStops)
		super(stops);

	function draw(target:s.graphics.RenderTarget)
		s.ui.graphics.gradients.LinearGradientDrawer.shader.render(target, this);
}
