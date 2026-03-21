package s.markup.elements.gradients;

@:allow(s.markup.graphics.gradients.RadialGradientDrawer)
class RadialGradient extends Gradient {
	public function new() {
		super();
		start = {x: 0.5, y: 0.5};
		end = {x: 1.0, y: 0.5};
	}

	function draw(target:Texture) {
		s.markup.graphics.gradients.RadialGradientDrawer.shader.render(target, this);
	}
}
