package s.geometry;

import s.math.Vec2;
import s.math.SMath;

extern abstract Size(Vec2) from Vec2 to Vec2 {
	public var width(get, set):Float;
	public var height(get, set):Float;

	public inline function new(width:Float, height:Float):Size {
		this = new Vec2(width, height);
	}

	@:from
	public static inline function fromString(value:String):Size {
		var size = value.split("x");
		return new Size(Std.parseFloat(size[0]), Std.parseFloat(size[1]));
	}

	@:to
	private inline function toSizeI():SizeI {
		return SizeI.fromSize(this);
	}

	@:to
	public inline function toString():String {
		return '${width}x${height}';
	}

	private inline function get_width():Float {
		return this.x;
	}

	private inline function set_width(value:Float):Float {
		this.x = value;
		return value;
	}

	private inline function get_height():Float {
		return this.y;
	}

	private inline function set_height(value:Float):Float {
		this.y = value;
		return value;
	}
}
