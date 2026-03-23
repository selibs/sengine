package s.geometry;

import s.math.Vec4I;

@:forward(x, y)
@:forward.new
extern abstract RectI(Vec4I) from Vec4I to Vec4I {
	public var width(get, set):Int;
	public var height(get, set):Int;
	public var position(get, set):PositionI;
	public var size(get, set):SizeI;

	@:from
	public static inline function fromBoundsI(value:BoundsI):RectI {
		return new RectI(value.left, value.top, value.right - value.left, value.bottom - value.top);
	}

	@:from
	public static inline function fromRect(value:Rect):RectI {
		return new RectI(Std.int(value.x), Std.int(value.y), Std.int(value.width), Std.int(value.height));
	}

	@:to
	private inline function toBoundsI():BoundsI {
		return BoundsI.fromRectI(this);
	}

	@:to
	private inline function toRect():Rect {
		return new Rect(this.x, this.y, width, height);
	}

	@:to
	public inline function toString():String {
		return '$size at $position';
	}

	private inline function get_width():Int {
		return this.z;
	}

	private inline function set_width(value:Int):Int {
		this.z = value;
		return value;
	}

	private inline function get_height():Int {
		return this.w;
	}

	private inline function set_height(value:Int):Int {
		this.w = value;
		return value;
	}

	private inline function get_position():PositionI {
		return new PositionI(this.x, this.y);
	}

	private inline function set_position(value:PositionI):PositionI {
		this.x = value.x;
		this.y = value.y;
		return value;
	}

	private inline function get_size():SizeI {
		return new SizeI(width, height);
	}

	private inline function set_size(value:SizeI):SizeI {
		width = size.width;
		height = size.height;
		return value;
	}
}
