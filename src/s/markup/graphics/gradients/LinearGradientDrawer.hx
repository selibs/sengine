package s.markup.graphics.gradients;

import s.markup.elements.gradients.LinearGradient;

@:allow(s.markup.elements.gradients.LinearGradient)
class LinearGradientDrawer extends GradientDrawer<LinearGradient> {
	function new() {
		super("gradient_linear");
	}
}
