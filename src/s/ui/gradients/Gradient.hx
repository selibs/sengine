package s.ui.gradients;

import s.math.Vec2;
import s.math.Interpolation;
import s.graphics.RenderTarget;

@:allow(s.ui.GradientStops)
@:allow(s.ui.graphics.gradients.GradientDrawer)
abstract class Gradient extends s.ui.elements.Drawable {
	var texture:RenderTarget;

	@:attr public var start:Vec2 = new Vec2(0.5, 0.0);
	@:attr public var end:Vec2 = new Vec2(0.5, 1.0);
	@:attr.attached public var stops(default, set):GradientStops;
	@:attr(gradient) @:clamp(1) public var resolution:Int = 256;
	@:attr(gradient) public var interpolation:Interpolation = Interpolation.Linear;

	public function new(?stops:GradientStops) {
		super();
		texture = new RenderTarget(resolution, 1);
		@:bypassAccessor this.stops = new GradientStops([], this);

		if (stops != null)
			this.stops = stops;
	}

	override function update() {
		super.update();

		if (!gradientDirty && !resolutionDirty)
			return;

		if (resolutionDirty) {
			texture.unload();
			texture = new RenderTarget(resolution, 1);
		}

		texture.context2D.begin();
		texture.context2D.clear(Transparent);
		texture.context2D.end();

		var ctx = texture.context1D;
		ctx.begin();
		final inverted = kha.Image.renderTargetsInvertedY();

		inline function setGradientPixel(x:Int, color:Color) {
			#if (cpp && kha_opengl)
			// Native OpenGL uses the raw bytes written through Graphics1.
			// Swap R/B here so the uploaded texture still ends up in RGBA order.
			color = Color.rgba(color.b, color.g, color.r, color.a);
			#end
			ctx.setPixel(inverted ? resolution - 1 - x : x, 0, color);
		}

		if (stops == null || stops.count == 0)
			for (i in 0...resolution)
				setGradientPixel(i, Transparent);
		else if (stops.count == 1) {
			var c = stops[0].color;
			for (i in 0...resolution)
				setGradientPixel(i, c);
		} else {
			var last = stops.count - 1;
			var j = 0;
			for (i in 0...resolution) {
				var p = resolution > 1 ? i / (resolution - 1) : 0.0;
				var c:Color;

				if (p <= stops[0].position)
					c = stops[0].color;
				else if (p >= stops[last].position)
					c = stops[last].color;
				else {
					while (j + 1 < stops.count && p > stops[j + 1].position)
						j++;

					var stop = stops[j];
					var next = stops[j + 1];
					var length = next.position - stop.position;
					var t = length == 0 ? 1.0 : (p - stop.position) / length;
					c = s.Color.mix(stop.color, next.color, interpolation(t));
				}

				setGradientPixel(i, c);
			}
		}

		ctx.end();
	}

	function set_stops(value:GradientStops) {
		return stops = new GradientStops(value != null ? value.stops : [], this);
	}
}
