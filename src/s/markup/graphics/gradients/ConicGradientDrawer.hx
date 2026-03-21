package s.markup.graphics.gradients;

import s.markup.elements.gradients.ConicGradient;

@:allow(s.markup.elements.gradients.ConicGradient)
class ConicGradientDrawer extends GradientDrawer<ConicGradient> {
	function new() {
		super("gradient_conic");
	}
}
