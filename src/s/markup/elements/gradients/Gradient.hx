package s.markup.elements.gradients;

import s.math.Vec2;

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

@:allow(s.markup.graphics.gradients.GradientDrawer)
abstract class Gradient extends DrawableElement {
	var gradient:Texture;
	var realStart:Vec2 = new Vec2(0.0, 0.0);
	var realEnd:Vec2 = new Vec2(0.0, 0.0);

	@:attr public var start:ElementPoint;
	@:attr public var end:ElementPoint;
	@:attr public var stops:GradientStops;
	@:attr public var interpolation:Interpolation = Interpolation.Linear;

	public function new() {
		super();
		color = White;
		start = {x: "50%", y: "0%"};
		end = {x: "50%", y: "100%"};
		gradient = new Texture(1, 256);
	}

	override function sync(target:Texture) {
		super.sync(target);

		DrawableElement.syncPoint(this, target, realStart, start, startIsDirty);
		DrawableElement.syncPoint(this, target, realEnd, end, endIsDirty);

		if (stopsIsDirty || interpolationIsDirty)
			syncGradient();
	}

	function syncGradient() {
		var ctx = gradient.context1D;
		ctx.begin();

		if (stops == null || stops.length == 0)
			for (i in 0...256)
				ctx.setPixel(0, i, Transparent);
		else if (stops.length == 1) {
			var c = stops[0].color;
			for (i in 0...256)
				ctx.setPixel(0, i, c);
		} else {
			var j = 0;
			var stop = stops[j];
			var next = stops[++j];

			for (i in 0...256) {
				var p = i / 256;
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
