package s.markup.geometry;

import s.math.Vec4I;

@:forward.new
extern abstract BoundsI(Vec4I) from Vec4I to Vec4I {
	public var left(get, set):Int;
	public var top(get, set):Int;
	public var right(get, set):Int;
	public var bottom(get, set):Int;

	public inline function new(left:Int, top:Int, right:Int, bottom:Int) {
		this = new Vec4I(left, top, right, bottom);
	}

	@:from
	public static inline function fromRectI(value:RectI):BoundsI {
		return new BoundsI(value.x, value.y, value.x + value.width, value.y + value.height);
	}

	@:from
	public static inline function fromBounds(value:Bounds):BoundsI {
		return new BoundsI(Std.int(value.left), Std.int(value.top), Std.int(value.right), Std.int(value.bottom));
	}

	@:to
	private inline function toBounds():Bounds {
		return new Bounds(left, top, right, bottom);
	}

	@:to
	private inline function toRect():Rect {
		return Rect.fromBounds(toBounds());
	}

	@:to
	public inline function toString():String {
		return '($left, $top, $right, $bottom)';
	}

	private inline function get_left():Int {
		return this.x;
	}

	private inline function set_left(value:Int):Int {
		this.x = value;
		return value;
	}

	private inline function get_top():Int {
		return this.y;
	}

	private inline function set_top(value:Int):Int {
		this.y = value;
		return value;
	}

	private inline function get_right():Int {
		return this.z;
	}

	private inline function set_right(value:Int):Int {
		this.z = value;
		return value;
	}

	private inline function get_bottom():Int {
		return this.w;
	}

	private inline function set_bottom(value:Int):Int {
		this.w = value;
		return value;
	}
}
