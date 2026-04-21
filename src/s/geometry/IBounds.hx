package s.geometry;

import s.math.IVec4;

@:forward.new
extern abstract IBounds(IVec4) {
	public var left(get, set):Int;
	public var top(get, set):Int;
	public var right(get, set):Int;
	public var bottom(get, set):Int;

	@:from
	public static inline function fromRectI(value:IRect):IBounds
		return new IBounds(value.x, value.y, value.x + value.width, value.y + value.height);

	@:from
	public static inline function fromBounds(value:Bounds):IBounds
		return new IBounds(Std.int(value.left), Std.int(value.top), Std.int(value.right), Std.int(value.bottom));

	public inline function new(left:Int, top:Int, right:Int, bottom:Int)
		this = new IVec4(left, top, right, bottom);

	@:to
	public inline function toString():String
		return '($left, $top, $right, $bottom)';

	@:to
	private inline function toBounds():Bounds
		return new Bounds(left, top, right, bottom);

	@:to
	private inline function toRect():Rect
		return Rect.fromBounds(toBounds());

	private inline function get_left():Int
		return this.x;

	private inline function set_left(value:Int):Int
		return this.x = value;

	private inline function get_top():Int
		return this.y;

	private inline function set_top(value:Int):Int
		return this.y = value;

	private inline function get_right():Int
		return this.z;

	private inline function set_right(value:Int):Int
		return this.z = value;

	private inline function get_bottom():Int
		return this.w;

	private inline function set_bottom(value:Int):Int
		return this.w = value;
}
