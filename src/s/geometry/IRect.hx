package s.geometry;

import s.math.IVec4;

@:forward(x, y)
@:forward.new
extern abstract IRect(IVec4) from IVec4 to IVec4 {
	public var width(get, set):Int;
	public var height(get, set):Int;
	public var position(get, set):IPosition;
	public var size(get, set):ISize;

	@:from
	public static inline function fromBoundsI(value:IBounds):IRect
		return new IRect(value.left, value.top, value.right - value.left, value.bottom - value.top);

	@:from
	public static inline function fromRect(value:Rect):IRect
		return new IRect(Std.int(value.x), Std.int(value.y), Std.int(value.width), Std.int(value.height));

	@:to
	private inline function toBoundsI():IBounds
		return IBounds.fromRectI(this);

	@:to
	private inline function toRect():Rect
		return new Rect(this.x, this.y, width, height);

	@:to
	public inline function toString():String
		return '$size at $position';

	private inline function get_width():Int
		return this.z;

	private inline function set_width(value:Int):Int
		return this.z = value;

	private inline function get_height():Int
		return this.w;

	private inline function set_height(value:Int):Int
		return this.w = value;

	private inline function get_position():IPosition
		return new IPosition(this.x, this.y);

	private inline function set_position(value:IPosition):IPosition {
		this.x = value.x;
		this.y = value.y;
		return value;
	}

	private inline function get_size():ISize
		return new ISize(width, height);

	private inline function set_size(value:ISize):ISize {
		width = size.width;
		height = size.height;
		return value;
	}
}
