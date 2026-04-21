package s.geometry;

import s.math.Vec4;
import s.math.SMath;

@:forward(x, y)
@:forward.new
extern abstract Rect(Vec4) from Vec4 to Vec4 {
	public var width(get, set):Float;
	public var height(get, set):Float;
	public var position(get, set):Position;
	public var size(get, set):Size;

	@:from
	public static inline function fromBounds(value:Bounds):Rect
		return new Rect(value.left, value.top, value.right - value.left, value.bottom - value.top);

	@:from
	public static inline function fromStruct(value:{
		x:Float,
		y:Float,
		width:Float,
		height:Float
	}):Rect
		return new Rect(value.x, value.y, value.width, value.height);

	@:to
	private inline function toBounds():Bounds
		return Bounds.fromRect(this);

	@:to
	private inline function toRectI():IRect
		return IRect.fromRect(this);

	@:to
	public inline function toString():String
		return '$size at $position';

	private inline function get_width():Float
		return this.z;

	private inline function set_width(value:Float):Float
		return this.z = value;

	private inline function get_height():Float
		return this.w;

	private inline function set_height(value:Float):Float
		return this.w = value;

	private inline function get_position():Position
		return new Position(this.x, this.y);

	private inline function set_position(value:Position):Position {
		this.x = value.x;
		this.y = value.y;
		return value;
	}

	private inline function get_size():Size
		return new Size(width, height);

	private inline function set_size(value:Size):Size {
		width = size.width;
		height = size.height;
		return value;
	}
}
