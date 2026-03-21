package s.markup;

import s.math.Vec3;
import s.math.Vec2;
import s.math.Mat3;

@:forward()
@:forward.new
extern abstract Transform2D(Mat3) from Mat3 to Mat3 {
	public static inline function identity()
		return Mat3.identity();

	@:from
	public static inline function fromStruct(value:{
		?translationX:Float,
		?translationY:Float,
		?scaleX:Float,
		?scaleY:Float,
		?rotation:Float
	}):Transform2D {
		var t:Transform2D = identity();
		if (value.translationX != null)
			t.translationX = value.translationX;
		if (value.translationY != null)
			t.translationY = value.translationY;
		if (value.scaleX != null)
			t.scaleX = value.scaleX;
		if (value.scaleY != null)
			t.scaleY = value.scaleY;
		if (value.rotation != null)
			t.rotation = value.rotation;
		return t;
	}

	@:from
	public static inline function fromStructVec2(value:{?translation:Vec2, ?scale:Vec2, ?rotation:Float}):Transform2D {
		var t:Transform2D = Mat3.identity();
		if (value.translation != null)
			t.translation = value.translation;
		if (value.scale != null)
			t.scale = value.scale;
		if (value.rotation != null)
			t.rotation = value.rotation;
		return t;
	}

	public var translationX(get, set):Float;
	public var translationY(get, set):Float;
	public var translation(get, set):Vec2;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scale(get, set):Vec2;
	public var rotation(get, set):Float;

	extern overload public inline function translate(x:Float, y:Float) {
		this *= Mat3.translation(x, y);
	}

	extern overload public inline function translate(value:Vec2) {
		translate(value.x, value.y);
	}

	extern overload public inline function translate(value:Float) {
		translate(value, value);
	}

	extern overload public inline function upscale(x:Float, y:Float) {
		this *= Mat3.scale(x, y);
	}

	extern overload public inline function upscale(value:Vec2) {
		upscale(value.x, value.y);
	}

	extern overload public inline function upscale(value:Float) {
		upscale(value, value);
	}

	extern overload public inline function upscale(x:Float, y:Float, origin:Vec2) {
		translate(-origin.x, -origin.y);
		upscale(x, y);
		translate(origin.x, origin.y);
	}

	extern overload public inline function upscale(value:Vec2, origin:Vec2) {
		upscale(value.x, value.y, origin);
	}

	extern overload public inline function upscale(value:Float, origin:Vec2) {
		upscale(value, value, origin);
	}

	extern overload public inline function rotate(value:Float) {
		this *= Mat3.rotation(value);
	}

	extern overload public inline function rotate(value:Float, origin:Vec2) {
		translate(-origin.x, -origin.y);
		rotate(value);
		translate(origin.x, origin.y);
	}

	@:op(a *= b)
	private inline function mulEq(b:Mat3):Mat3
		return this *= b;

	@:op(a *= b)
	private inline function mulEqScalar(f:Float):Mat3
		return this *= f;

	@:op(a /= b)
	private inline function divEq(b:Mat3):Mat3
		return this /= b;

	@:op(a /= b)
	private inline function divEqScalar(f:Float):Mat3
		return this /= f;

	@:op(a += b)
	private inline function addEq(b:Mat3):Mat3
		return this += b;

	@:op(a += b)
	private inline function addEqScalar(f:Float):Mat3
		return this += f;

	@:op(a -= b)
	private inline function subEq(b:Mat3):Mat3
		return this -= b;

	@:op(a -= b)
	private inline function subEqScalar(f:Float):Mat3
		return this -= f;

	@:op(a + b)
	private inline function add(n:Mat3):Mat3
		return this + n;

	@:op(a + b) @:commutative
	private inline function addScalar(f:Float):Mat3
		return this + f;

	@:op(a - b)
	private inline function sub(n:Mat3):Mat3
		return this - n;

	@:op(a - b)
	private inline function subScalar(f:Float):Mat3
		return this - f;

	@:op(a - b)
	private inline function subScalarInv(f:Float):Mat3
		return this - f;

	@:op(a * b)
	private inline function mul(n:Mat3):Mat3
		return this * n;

	@:op(a * b)
	private inline function postMulVec2(v:Vec2):Vec2
		return this * v;

	@:op(a * b)
	private inline function postMulVec3(v:Vec3):Vec3
		return this * v;

	@:op(a * b)
	private inline function preMulVec3(v:Vec3):Vec3
		return this * v;

	@:op(a * b) @:commutative
	private inline function mulScalar(f:Float):Mat3
		return @:privateAccess this.mulScalar(f);

	@:op(a / b)
	private inline function div(n:Mat3):Mat3
		return this / n;

	@:op(a / b)
	private inline function divScalar(f:Float):Mat3
		return this / f;

	@:op(a / b)
	private inline function divScalarInv(f:Float):Mat3
		return this / f;

	@:op(a == b)
	private inline function equal(n:Mat3):Bool
		return this == n;

	@:op(a != b)
	private inline function notEqual(n:Mat3):Bool
		return this != n;

	private inline function get_translationX():Float
		return this._20;

	private inline function set_translationX(value:Float)
		return this._20 = value;

	private inline function get_translationY():Float
		return this._21;

	private inline function set_translationY(value:Float)
		return this._21 = value;

	private inline function get_translation():Vec2
		return new Vec2(translationX, translationY);

	private inline function set_translation(value:Vec2) {
		translationX = value.x;
		translationY = value.y;
		return value;
	}

	private inline function get_scaleX():Float
		return Math.sqrt(this._00 * this._00 + this._10 * this._10);

	private inline function set_scaleX(value:Float) {
		var s = scaleX;
		if (s != 0) {
			var d = value / s;
			this._00 *= d;
			this._10 *= d;
		} else {
			this._00 = value;
			this._10 = value;
		}
		return value;
	}

	private inline function get_scaleY():Float
		return Math.sqrt(this._01 * this._01 + this._11 * this._11);

	private inline function set_scaleY(value:Float) {
		var s = scaleY;
		if (s != 0) {
			var d = value / s;
			this._01 *= d;
			this._11 *= d;
		} else {
			this._01 = value;
			this._11 = value;
		}
		return value;
	}

	private inline function get_scale():Vec2
		return new Vec2(scaleX, scaleY);

	private inline function set_scale(value:Vec2) {
		scaleX = value.x;
		scaleY = value.y;
		return value;
	}

	private inline function get_rotation():Float
		return Math.atan2(this._10, this._00);

	private inline function set_rotation(value:Float) {
		var c = Math.cos(value);
		var s = Math.sin(value);
		var sx = scaleX;
		var sy = scaleY;

		this._00 = c * sx;
		this._10 = s * sx;
		this._01 = -s * sy;
		this._11 = c * sy;
		return value;
	}
}
