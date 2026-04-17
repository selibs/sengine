package s.geometry;

import s.math.IVec2;

extern abstract SizeI(IVec2) from IVec2 to IVec2 {
	public var width(get, set):Int;
	public var height(get, set):Int;

	public inline function new(width:Int, height:Int):SizeI {
		this = new IVec2(width, height);
	}

	@:from
	public static inline function fromSize(value:Size):SizeI {
		return new SizeI(Std.int(value.width), Std.int(value.height));
	}

	@:from
	public static inline function fromString(value:String):SizeI {
		var size = value.split("x");
		return new SizeI(Std.parseInt(size[0]), Std.parseInt(size[1]));
	}

	@:to
	private inline function toSize():Size {
		return new Size(width, height);
	}

	@:to
	public inline function toString():String {
		return '${width}x${height}';
	}

	private inline function get_width():Int {
		return this.x;
	}

	private inline function set_width(value:Int):Int {
		this.x = value;
		return value;
	}

	private inline function get_height():Int {
		return this.y;
	}

	private inline function set_height(value:Int):Int {
		this.y = value;
		return value;
	}
}
