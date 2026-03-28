package s.markup.elements.gradients;

import s.math.Vec2;
import s.graphics.RenderTarget;

@:structInit
class GradientStop implements s.shortcut.Shortcut {
	@:attr public var color:Color;
	@:attr public var position:Float;
}

@:forward.new
@:forward(length, concat, slice, toString, contains, indexOf, lastIndexOf, copy, iterator, keyValueIterator, map, filter,)
extern abstract GradientStops(Array<GradientStop>) from Array<GradientStop> {
	@:op([])
	inline function arrayRead(i:Int)
		return this[i];
}

@:dox(hide)
@:allow(s.markup.graphics.gradients.GradientDrawer)
abstract class Gradient extends DrawableElement {
	var gradient:RenderTarget;

	public var start:Vec2 = new Vec2(0.5, 0.0);
	public var end:Vec2 = new Vec2(0.5, 1.0);
	@:attr public var stops:GradientStops;
	@:attr public var resolution(default, set):Int = 256;
	@:attr public var interpolation:Interpolation = Interpolation.Linear;

	public function new() {
		super();
		gradient = new RenderTarget(1, resolution);
	}

	override function sync() {
		super.sync();

		if (stopsIsDirty || resolutionIsDirty || interpolationIsDirty) {
			if (resolutionIsDirty) {
				gradient.unload();
				gradient = new RenderTarget(1, resolution);
			}

			var ctx = gradient.context1D;
			ctx.begin();

			if (stops == null || stops.length == 0)
				for (i in 0...resolution)
					ctx.setPixel(0, i, Transparent);
			else if (stops.length == 1) {
				var c = stops[0].color;
				for (i in 0...resolution)
					ctx.setPixel(0, i, c);
			} else {
				var j = 0;
				var stop = stops[j];
				var next = stops[++j];

				for (i in 0...resolution) {
					var p = i / resolution;
					if (p > next.position) {
						stop = next;
						next = stops[++j];
					}
					var t = (p - stop.position) / (next.position - stop.position);
					ctx.setPixel(0, i, s.Color.mix(stop.color, next.color, interpolation(t)));
				}
			}

			ctx.end();
		}
	}

	inline function set_resolution(value:Int):Int
		return resolution = value > 0 ? value : 1;
}
