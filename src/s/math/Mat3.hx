package s.math;

import kha.math.FastMatrix3 as KhaMat3;

@:nullSafety
@:forward.new
@:forward(_00, _10, _20, _01, _11, _21, _02, _12, _22)
extern abstract Mat3(KhaMat3) from KhaMat3 to KhaMat3 {
	private var self(get, never):Mat3;

	private inline function get_self()
		return (this : Mat3);

	public static inline function identity():Mat3 {
		return KhaMat3.identity();
	}

	public static inline function empty():Mat3 {
		return KhaMat3.empty();
	}

	public static inline function translation(x:Float, y:Float):Mat3 {
		return KhaMat3.translation(x, y);
	}

	public static inline function scale(x:Float, y:Float):Mat3 {
		return KhaMat3.scale(x, y);
	}

	public static inline function rotation(angle:Float):Mat3 {
		return KhaMat3.rotation(angle);
	}

	public static inline function orthogonalProjection(left:Float, right:Float, bottom:Float, top:Float):Mat3 {
		var tx = -(right + left) / (right - left);
		var ty = -(top + bottom) / (top - bottom);

		return new Mat3(2 / (right - left), 0, tx, 0, 2.0 / (top - bottom), ty, 0, 0, 1);
	}

	public static inline function lookAt(eye:Vec2, at:Vec2, up:Vec2):Mat3 {
		var zaxis = (at - eye).normalize();
		return new Mat3(-zaxis.y, zaxis.x, zaxis.y * eye.x - zaxis.x * eye.y, -zaxis.x, -zaxis.y, zaxis.x * eye.x + zaxis.y * eye.y, 0, 0, 1);
	}

	public inline function set(a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float, a12:Float, a22:Float) {
		this._00 = a00;
		this._10 = a10;
		this._20 = a20;
		this._01 = a01;
		this._11 = a11;
		this._21 = a21;
		this._02 = a02;
		this._12 = a12;
		this._22 = a22;
	}

	public inline function copyFrom(v:Mat3) {
		this.setFrom(v);
		return this;
	}

	public inline function clone():Mat3 {
		return new Mat3(this._00, this._10, this._20, this._01, this._11, this._21, this._02, this._12, this._22);
	}

	public inline function matrixCompMult(n:Mat3):Mat3 {
		return new Mat3(this._00 * n._00, this._10 * n._10, this._20 * n._20, this._01 * n._01, this._11 * n._11, this._21 * n._21, this._02 * n._02,
			this._12 * n._12, this._22 * n._22);
	}

	// extended methods

	public inline function transpose():Mat3 {
		return new Mat3(this._00, this._01, this._02, this._10, this._11, this._12, this._20, this._21, this._22);
	}

	public inline function determinant():Float {
		return (this._00 * (this._22 * this._11 - this._21 * this._12) + this._10 * (-this._22 * this._01 + this._21 * this._02)
			+ this._20 * (this._12 * this._01 - this._11 * this._02));
	}

	public inline function inverse():Mat3 {
		var b01 = this._22 * this._11 - this._21 * this._12;
		var b11 = -this._22 * this._01 + this._21 * this._02;
		var b21 = this._12 * this._01 - this._11 * this._02;

		// determinant
		var det = this._00 * b01 + this._10 * b11 + this._20 * b21;

		var f = 1.0 / det;

		return new Mat3(b01 * f, (-this._22 * this._10 + this._20 * this._12) * f, (this._21 * this._10 - this._20 * this._11) * f, b11 * f,
			(this._22 * this._00 - this._20 * this._02) * f, (-this._21 * this._00 + this._20 * this._01) * f, b21 * f,
			(-this._12 * this._00 + this._10 * this._02) * f, (this._11 * this._00 - this._10 * this._01) * f);
	}

	public inline function adjoint():Mat3 {
		return new Mat3(this._11 * this._22
			- this._21 * this._12, this._20 * this._12
			- this._10 * this._22, this._10 * this._21
			- this._20 * this._11,
			this._21 * this._02
			- this._01 * this._22, this._00 * this._22
			- this._20 * this._02, this._20 * this._01
			- this._00 * this._21,
			this._01 * this._12
			- this._11 * this._02, this._10 * this._02
			- this._00 * this._12, this._00 * this._11
			- this._10 * this._01);
	}

	public inline function toString() {
		return 'mat3('
			+ '${this._00}, ${this._10}, ${this._20}, '
			+ '${this._01}, ${this._11}, ${this._21}, '
			+ '${this._02}, ${this._12}, ${this._22}'
			+ ')';
	}

	@:op(-a)
	private inline function neg() {
		return new Mat3(-this._00, -this._10, -this._20, -this._01, -this._11, -this._21, -this._02, -this._12, -this._22);
	}

	@:op(++a)
	private inline function prefixIncrement() {
		++this._00;
		++this._10;
		++this._20;
		++this._01;
		++this._11;
		++this._21;
		++this._02;
		++this._12;
		++this._22;
		return clone();
	}

	@:op(--a)
	private inline function prefixDecrement() {
		--this._00;
		--this._10;
		--this._20;
		--this._01;
		--this._11;
		--this._21;
		--this._02;
		--this._12;
		--this._22;
		return clone();
	}

	@:op(a++)
	private inline function postfixIncrement() {
		var ret = clone();
		++this._00;
		++this._10;
		++this._20;
		++this._01;
		++this._11;
		++this._21;
		++this._02;
		++this._12;
		++this._22;
		return ret;
	}

	@:op(a--)
	private inline function postfixDecrement() {
		var ret = clone();
		--this._00;
		--this._10;
		--this._20;
		--this._01;
		--this._11;
		--this._21;
		--this._02;
		--this._12;
		--this._22;
		return ret;
	}

	// assignment overload should come before other binary ops to ensure they have priority

	@:op(a *= b)
	private inline function mulEq(b:Mat3):Mat3
		return copyFrom(self * b);

	@:op(a *= b)
	private inline function mulEqScalar(f:Float):Mat3
		return copyFrom(mulScalar(f));

	@:op(a /= b)
	private inline function divEq(b:Mat3):Mat3
		return copyFrom(self / b);

	@:op(a /= b)
	private inline function divEqScalar(f:Float):Mat3
		return copyFrom(self / f);

	@:op(a += b)
	private inline function addEq(b:Mat3):Mat3
		return copyFrom(self + b);

	@:op(a += b)
	private inline function addEqScalar(f:Float):Mat3
		return copyFrom(self + f);

	@:op(a -= b)
	private inline function subEq(b:Mat3):Mat3
		return copyFrom(self - b);

	@:op(a -= b)
	private inline function subEqScalar(f:Float):Mat3
		return copyFrom(self - f);

	@:op(a + b)
	private inline function add(n:Mat3):Mat3 {
		return new Mat3(this._00
			+ n._00, this._10
			+ n._10, this._20
			+ n._20, this._01
			+ n._01, this._11
			+ n._11, this._21
			+ n._21, this._02
			+ n._02,
			this._12
			+ n._12, this._22
			+ n._22);
	}

	@:op(a + b) @:commutative
	private inline function addScalar(f:Float):Mat3 {
		return new Mat3(this._00
			+ f, this._10
			+ f, this._20
			+ f, this._01
			+ f, this._11
			+ f, this._21
			+ f, this._02
			+ f, this._12
			+ f, this._22
			+ f);
	}

	@:op(a - b)
	private inline function sub(n:Mat3):Mat3 {
		return new Mat3(this._00
			- n._00, this._10
			- n._10, this._20
			- n._20, this._01
			- n._01, this._11
			- n._11, this._21
			- n._21, this._02
			- n._02,
			this._12
			- n._12, this._22
			- n._22);
	}

	@:op(a - b)
	private inline function subScalar(f:Float):Mat3 {
		return new Mat3(this._00
			- f, this._10
			- f, this._20
			- f, this._01
			- f, this._11
			- f, this._21
			- f, this._02
			- f, this._12
			- f, this._22
			- f);
	}

	@:op(a - b)
	private inline function subScalarInv(f:Float):Mat3 {
		return new Mat3(f
			- this._00, f
			- this._10, f
			- this._20, f
			- this._01, f
			- this._11, f
			- this._21, f
			- this._02, f
			- this._12, f
			- this._22);
	}

	@:op(a * b)
	private inline function mul(n:Mat3):Mat3 {
		return new Mat3(this._00 * n._00
			+ this._01 * n._10
			+ this._02 * n._20, this._10 * n._00
			+ this._11 * n._10
			+ this._12 * n._20,
			this._20 * n._00
			+ this._21 * n._10
			+ this._22 * n._20, this._00 * n._01
			+ this._01 * n._11
			+ this._02 * n._21,
			this._10 * n._01
			+ this._11 * n._11
			+ this._12 * n._21, this._20 * n._01
			+ this._21 * n._11
			+ this._22 * n._21,
			this._00 * n._02
			+ this._01 * n._12
			+ this._02 * n._22, this._10 * n._02
			+ this._11 * n._12
			+ this._12 * n._22,
			this._20 * n._02
			+ this._21 * n._12
			+ this._22 * n._22);
	}

	@:op(a * b)
	private inline function postMulVec2(v:Vec2):Vec2 {
		return (this : KhaMat3).multvec(v);
	}

	@:op(a * b)
	private inline function postMulVec3(v:Vec3):Vec3 {
		return new Vec3(this._00 * v.x
			+ this._01 * v.y
			+ this._02 * v.z, this._10 * v.x
			+ this._11 * v.y
			+ this._12 * v.z,
			this._20 * v.x
			+ this._21 * v.y
			+ this._22 * v.z);
	}

	@:op(a * b)
	private inline function preMulVec3(v:Vec3):Vec3 {
		return new Vec3(v.dot(new Vec3(this._00, this._10, this._20)), v.dot(new Vec3(this._01, this._11, this._21)),
			v.dot(new Vec3(this._02, this._12, this._22)));
	}

	@:op(a * b) @:commutative
	private inline function mulScalar(f:Float):Mat3 {
		return new Mat3(this._00 * f, this._10 * f, this._20 * f, this._01 * f, this._11 * f, this._21 * f, this._02 * f, this._12 * f, this._22 * f);
	}

	@:op(a / b)
	private inline function div(n:Mat3):Mat3
		return matrixCompMult(n.divScalarInv(1.0));

	@:op(a / b)
	private inline function divScalar(f:Float):Mat3 {
		return new Mat3(this._00 / f, this._10 / f, this._20 / f, this._01 / f, this._11 / f, this._21 / f, this._02 / f, this._12 / f, this._22 / f);
	}

	@:op(a / b)
	private inline function divScalarInv(f:Float):Mat3 {
		return new Mat3(f / this._00, f / this._10, f / this._20, f / this._01, f / this._11, f / this._21, f / this._02, f / this._12, f / this._22);
	}

	@:op(a == b)
	private inline function equal(n:Mat3):Bool {
		return this._00 == n._00 && this._10 == n._10 && this._20 == n._20 && this._01 == n._01 && this._11 == n._11 && this._21 == n._21
			&& this._02 == n._02 && this._12 == n._12 && this._22 == n._22;
	}

	@:op(a != b)
	private inline function notEqual(n:Mat3):Bool
		return !equal(n);

	/**
		Copies matrix elements in column-major order into a type that supports array-write access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:haxe.macro.Expr.ExprOf<Mat3>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyIntoArray(array, i);
			self[1].copyIntoArray(array, i + 3);
			self[2].copyIntoArray(array, i + 6);
			array;
		}
	}

	/**
		Copies matrix elements in column-major order from a type that supports array-read access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):Mat3 {})
	public macro function copyFromArray(self:haxe.macro.Expr.ExprOf<Mat3>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyFromArray(array, i);
			self[1].copyFromArray(array, i + 3);
			self[2].copyFromArray(array, i + 6);
			self;
		}
	}

	// static macros

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>):ExprOf<Mat3> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Mat3(array[0 + i], array[1 + i], array[2 + i], array[3 + i], array[4 + i], array[5 + i], array[6 + i], array[7 + i], array[8 + i]);
		}
	}
}
