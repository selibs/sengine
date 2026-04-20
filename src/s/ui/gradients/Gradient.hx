package s.ui.gradients;

import s.math.Vec2;
import s.math.Interpolation;
import s.graphics.RenderTarget;

@:structInit
class GradientStop implements s.shortcut.Shortcut {
	@:attr public var position:Float;
	@:attr public var color:Color;
}

@:forward.new
@:forward(length, concat, slice, toString, contains, indexOf, lastIndexOf, copy, iterator, keyValueIterator, map, filter)
extern abstract GradientStops(Array<GradientStop>) from Array<GradientStop> {
	@:op([])
	inline function arrayRead(i:Int)
		return this[i];
}

@:dox(hide)
@:allow(s.ui.graphics.gradients.GradientDrawer)
abstract class Gradient extends s.ui.elements.Drawable {
	var gradient:RenderTarget;

	public var start:Vec2 = new Vec2(0.5, 0.0);
	public var end:Vec2 = new Vec2(0.5, 1.0);
	@:attr(gradient) public var stops:GradientStops;
	@:attr(gradient) public var resolution(default, set):Int = 256;
	@:attr(gradient) public var interpolation:Interpolation = Interpolation.Linear;

	public function new(?stops:GradientStops) {
		super();
		gradient = new RenderTarget(resolution, 1);
		if (stops != null)
			this.stops = stops;
	}

	override function update() {
		super.update();

		if (!gradientDirty && !resolutionDirty)
			return;

		if (resolutionDirty) {
			gradient.unload();
			gradient = new RenderTarget(resolution, 1);
		}

		gradient.context2D.begin();
		gradient.context2D.clear(Transparent);
		gradient.context2D.end();

		var ctx = gradient.context1D;
		ctx.begin();
		final inverted = kha.Image.renderTargetsInvertedY();

		inline function setGradientPixel(x:Int, color:Color)
			ctx.setPixel(inverted ? resolution - 1 - x : x, 0, color);

		if (stops == null || stops.length == 0)
			for (i in 0...resolution)
				setGradientPixel(i, Transparent);
		else if (stops.length == 1) {
			var c = stops[0].color;
			for (i in 0...resolution)
				setGradientPixel(i, c);
		} else {
			var last = stops.length - 1;
			var j = 0;
			for (i in 0...resolution) {
				var p = resolution > 1 ? i / (resolution - 1) : 0.0;
				var c:Color;

				if (p <= stops[0].position)
					c = stops[0].color;
				else if (p >= stops[last].position)
					c = stops[last].color;
				else {
					while (j + 1 < stops.length && p > stops[j + 1].position)
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

	inline function set_resolution(value:Int):Int
		return resolution = value > 0 ? value : 1;
}
