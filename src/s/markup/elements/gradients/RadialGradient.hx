package s.markup.elements.gradients;

@:allow(s.markup.graphics.gradients.RadialGradientDrawer)
class RadialGradient extends Gradient {
	public function new() {
		super();
		start = {x: "50%", y: "50%"};
		end = {x: "100%", y: "50%"};
	}

	function draw(target:Texture) {
		s.markup.graphics.gradients.RadialGradientDrawer.shader.render(target, this);
	}
}
