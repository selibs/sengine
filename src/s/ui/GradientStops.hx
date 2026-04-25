package s.ui;

import s.ui.gradients.Gradient;
import s.shortcut.AttachedAttribute;

@:forward
@:forward.new
@:allow(s.ui.GradientStops)
extern abstract GradientStop(GradientStopData) {
	@:from
	public static inline function fromStruct(value:{position:Float, color:Color})
		return new GradientStop(value.position, value.color);

	overload public inline function new(position:Float, color:Color)
		this = new GradientStopData(position, color, null);

	overload private inline function new(position:Float, color:Color, stops:GradientStopsData)
		this = new GradientStopData(position, color, stops);
}

@:forward
@:allow(s.ui.gradients.Gradient)
extern abstract GradientStops(GradientStopsData) {
	@:from
	public static inline function fromMap(value:Map<Float, Color>)
		return fromStops([for (p in value.keys()) {position: p, color: value[p]}]);

	@:from
	public static inline function fromArray(value:Array<Color>) {
		var m = value.length - 1;
		return fromStops([for (i in 0...value.length) {position: i / m, color: value[i]}]);
	}

	@:from
	public static inline function fromStops(value:Array<GradientStop>)
		return new GradientStops(value);

	private var stops(get, never):Array<GradientStop>;

	public var count(get, never):Int;

	overload public inline function new(?stops:Array<GradientStop>) {
		this = new GradientStopsData();
		if (stops != null)
			for (stop in stops)
				set(stop.position, stop.color);
	}

	overload private inline function new(?stops:Array<GradientStop>, element:Gradient) {
		this = new GradientStopsData(element);
		if (stops != null)
			for (stop in stops)
				set(stop.position, stop.color);
	}

	overload public inline function set(i:Int, color:Color):Void {
		if (0 > i || i >= count)
			return;
		stops[i].color = color;
		this.markDirty();
	}

	overload public inline function set(position:Float, color:Color):Void {
		var i = 0;
		var b = false;
		for (stop in stops)
			if (stop.position < position)
				++i;
			else if (Math.abs(stop.position - position) < 1e-4) {
				stop.color = color;
				b = true;
			} else
				break;
		if (!b)
			stops.insert(i, new GradientStop(position, color, this));
		this.markDirty();
	}

	overload public inline function remove(i:Int):Bool {
		var s = stops.splice(i, 1);
		if (s.length == 1) {
			@:privateAccess s[0].object = null;
			this.markDirty();
			return true;
		}
		return false;
	}

	overload public inline function remove(position:Float):Bool {
		var i = 0;
		var b = false;
		for (stop in stops)
			if (stop.position < position)
				++i;
			else if (Math.abs(stop.position - position) < 1e-4) {
				b = true;
				stops.splice(i, 1);
				@:privateAccess stop.object = null;
				this.markDirty();
				break;
			}
		return b;
	}

	public inline function clear() {
		if (count <= 0)
			return false;
		while (count > 0)
			@:privateAccess stops.pop().object = null;
		this.markDirty();
		return true;
	}

	private inline function iterator()
		return this.stops.iterator();

	private inline function get_stops()
		return this.stops;

	private inline function get_count():Int
		return stops.length;

	@:op([])
	private inline function arrayRead(i:Int)
		return stops[i];
}

@:allow(s.ui.GradientStop)
private class GradientStopData extends AttachedAttribute<GradientStopsData> {
	@:attr public var position:Float;
	@:attr public var color:Color;

	function new(position:Float, color:Color, stops:GradientStopsData) {
		super(stops);
		this.position = position;
		this.color = color;
	}
}

@:allow(s.ui.GradientStops)
private class GradientStopsData extends AttachedAttribute<Gradient> {
	final stops:Array<GradientStop> = [];

	override function set_dirty(value:Bool):Bool {
		if (value && object != null)
			object.gradientDirty = true;
		return dirty = value;
	}
}
