package s.geometry;

import s.math.Vec4;
import s.math.SMath;

@:forward.new
extern abstract Bounds(Vec4) from Vec4 to Vec4 {
	public var left(get, set):Float;
	public var top(get, set):Float;
	public var right(get, set):Float;
	public var bottom(get, set):Float;

	@:from
	public static inline function fromRect(value:Rect):Bounds
		return new Bounds(value.x, value.y, value.x + value.width, value.y + value.height);

	public inline function new(left:Float, top:Float, right:Float, bottom:Float)
		this = new Vec4(left, top, right, bottom);

	@:to
	public inline function toString():String
		return '($left, $top, $right, $bottom)';

	@:to
	private inline function toBoundsI():IBounds
		return IBounds.fromBounds(this);

	@:to
	private inline function toRect():Rect
		return Rect.fromBounds(this);

	private inline function get_left():Float
		return this.x;

	private inline function set_left(value:Float):Float
		return this.x = value;

	private inline function get_top():Float
		return this.y;

	private inline function set_top(value:Float):Float
		return this.y = value;

	private inline function get_right():Float
		return this.z;

	private inline function set_right(value:Float):Float
		return this.z = value;

	private inline function get_bottom():Float
		return this.w;

	private inline function set_bottom(value:Float):Float
		return this.w = value;
}
