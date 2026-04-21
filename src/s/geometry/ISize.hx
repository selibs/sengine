package s.geometry;

import s.math.IVec2;

extern abstract ISize(IVec2) {
	public var width(get, set):Int;
	public var height(get, set):Int;

	@:from
	public static inline function fromSize(value:Size):ISize
		return new ISize(value.width, value.height);

	@:from
	public static inline function fromString(value:String):ISize {
		var size = value.split("x");
		return new ISize(Std.parseInt(size[0]), Std.parseInt(size[1]));
	}

	overload public inline function new(width:Float, height:Float):ISize
		this = new IVec2(Std.int(width), Std.int(height));

	overload public inline function new(width:Int, height:Int):ISize
		this = new IVec2(width, height);

	@:to
	private inline function toSize():Size
		return new Size(width, height);

	@:to
	public inline function toString():String
		return '${width}x${height}';

	private inline function get_width():Int
		return this.x;

	private inline function set_width(value:Int):Int
		return this.x = value;

	private inline function get_height():Int
		return this.y;

	private inline function set_height(value:Int):Int
		return this.y = value;
}
