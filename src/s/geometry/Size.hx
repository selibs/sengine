package s.geometry;

import s.math.Vec2;
import s.math.SMath;

extern abstract Size(Vec2) from Vec2 to Vec2 {
	public var width(get, set):Float;
	public var height(get, set):Float;

	@:from
	public static inline function fromString(value:String):Size {
		var size = value.split("x");
		return new Size(Std.parseFloat(size[0]), Std.parseFloat(size[1]));
	}

	public inline function new(width:Float, height:Float):Size
		this = new Vec2(width, height);

	@:to
	public inline function toString():String
		return '${width}x${height}';

	@:to
	private inline function toSizeI():ISize
		return ISize.fromSize(this);

	private inline function get_width():Float
		return this.x;

	private inline function set_width(value:Float):Float
		return this.x = value;

	private inline function get_height():Float
		return this.y;

	private inline function set_height(value:Float):Float
		return this.y = value;
}
