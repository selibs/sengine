package s.markup.elements.gradients;

@:allow(s.markup.graphics.gradients.ConicGradientDrawer)
class ConicGradient extends Gradient {
	public function new() {
		super();
		start = {x: "50%", y: "50%"};
		end = {x: "100%", y: "50%"};
	}

	function draw(target:Texture) {
		s.markup.graphics.gradients.ConicGradientDrawer.shader.render(target, this);
	}
}
