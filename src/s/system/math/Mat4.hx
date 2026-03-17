package s.system.math;

import kha.math.FastMatrix4 as KhaMat4;

@:nullSafety
@:forward.new
@:forward(_00, _10, _20, _30, _01, _11, _21, _31, _02, _12, _22, _32, _03, _13, _23, _33)
extern abstract Mat4(KhaMat4) from KhaMat4 to KhaMat4 {
	public static inline function identity():Mat4 {
		return KhaMat4.identity();
	}

	public static inline function empty():Mat4 {
		return KhaMat4.empty();
	}

	public static inline function translation(x:Float, y:Float, z:Float):Mat4 {
		return KhaMat4.translation(x, y, z);
	}

	public static inline function scale(x:Float, y:Float, z:Float):Mat4 {
		return KhaMat4.scale(x, y, z);
	}

	public static inline function rotation(yaw:Float, pitch:Float, roll:Float):Mat4 {
		return KhaMat4.rotation(yaw, pitch, roll);
	}

	public static inline function orthogonalProjection(left:Float, right:Float, bottom:Float, top:Float, zn:Float, zf:Float):Mat4 {
		return KhaMat4.orthogonalProjection(left, right, bottom, top, zn, zf);
	}

	public static inline function perspectiveProjection(fovY:Float, aspect:Float, zn:Float, zf:Float):Mat4 {
		return KhaMat4.perspectiveProjection(fovY, aspect, zn, zf);
	}

	public inline function set(a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float, a31:Float, a02:Float, a12:Float, a22:Float,
			a32:Float, a03:Float, a13:Float, a23:Float, a33:Float) {
		this._00 = a00;
		this._10 = a10;
		this._20 = a20;
		this._30 = a30;
		this._01 = a01;
		this._11 = a11;
		this._21 = a21;
		this._31 = a31;
		this._02 = a02;
		this._12 = a12;
		this._22 = a22;
		this._32 = a32;
		this._03 = a03;
		this._13 = a13;
		this._23 = a23;
		this._33 = a33;
	}

	public inline function copyFrom(v:Mat4) {
		this.setFrom(v);
		return this;
	}

	public inline function clone():Mat4 {
		return new Mat4(this._00, this._10, this._20, this._30, this._01, this._11, this._21, this._31, this._02, this._12, this._22, this._32, this._03,
			this._13, this._23, this._33);
	}

	public inline function matrixCompMult(n:Mat4):Mat4 {
		return new Mat4(this._00 * n._00, this._10 * n._10, this._20 * n._20, this._30 * n._30, this._01 * n._01, this._11 * n._11, this._21 * n._21,
			this._31 * n._31, this._02 * n._02, this._12 * n._12, this._22 * n._22, this._32 * n._32, this._03 * n._03, this._13 * n._13, this._23 * n._23,
			this._33 * n._33);
	}

	// extended methods

	public inline function transpose():Mat4 {
		return new Mat4(this._00, this._01, this._02, this._03, this._10, this._11, this._12, this._13, this._20, this._21, this._22, this._23, this._30,
			this._31, this._32, this._33);
	}

	public inline function determinant():Float {
		var b0 = this._00 * this._11 - this._10 * this._01;
		var b1 = this._00 * this._21 - this._20 * this._01;
		var b2 = this._10 * this._21 - this._20 * this._11;
		var b3 = this._02 * this._13 - this._12 * this._03;
		var b4 = this._02 * this._23 - this._22 * this._03;
		var b5 = this._12 * this._23 - this._22 * this._13;
		var b6 = this._00 * b5 - this._10 * b4 + this._20 * b3;
		var b7 = this._01 * b5 - this._11 * b4 + this._21 * b3;
		var b8 = this._02 * b2 - this._12 * b1 + this._22 * b0;
		var b9 = this._03 * b2 - this._13 * b1 + this._23 * b0;
		return this._31 * b6 - this._30 * b7 + this._33 * b8 - this._32 * b9;
	}

	public inline function inverse():Mat4 {
		var b00 = this._00 * this._11 - this._10 * this._01;
		var b01 = this._00 * this._21 - this._20 * this._01;
		var b02 = this._00 * this._31 - this._30 * this._01;
		var b03 = this._10 * this._21 - this._20 * this._11;
		var b04 = this._10 * this._31 - this._30 * this._11;
		var b05 = this._20 * this._31 - this._30 * this._21;
		var b06 = this._02 * this._13 - this._12 * this._03;
		var b07 = this._02 * this._23 - this._22 * this._03;
		var b08 = this._02 * this._33 - this._32 * this._03;
		var b09 = this._12 * this._23 - this._22 * this._13;
		var b10 = this._12 * this._33 - this._32 * this._13;
		var b11 = this._22 * this._33 - this._32 * this._23;

		// determinant
		var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

		var f = 1.0 / det;

		return new Mat4((this._11 * b11 - this._21 * b10 + this._31 * b09) * f, (this._20 * b10 - this._10 * b11 - this._30 * b09) * f,
			(this._13 * b05 - this._23 * b04 + this._33 * b03) * f, (this._22 * b04 - this._12 * b05 - this._32 * b03) * f,
			(this._21 * b08 - this._01 * b11 - this._31 * b07) * f, (this._00 * b11 - this._20 * b08 + this._30 * b07) * f,
			(this._23 * b02 - this._03 * b05 - this._33 * b01) * f, (this._02 * b05 - this._22 * b02 + this._32 * b01) * f,
			(this._01 * b10 - this._11 * b08 + this._31 * b06) * f, (this._10 * b08 - this._00 * b10 - this._30 * b06) * f,
			(this._03 * b04 - this._13 * b02 + this._33 * b00) * f, (this._12 * b02 - this._02 * b04 - this._32 * b00) * f,
			(this._11 * b07 - this._01 * b09 - this._21 * b06) * f, (this._00 * b09 - this._10 * b07 + this._20 * b06) * f,
			(this._13 * b01 - this._03 * b03 - this._23 * b00) * f, (this._02 * b03 - this._12 * b01 + this._22 * b00) * f);
	}

	public inline function adjoint():Mat4 {
		var b00 = this._00 * this._11 - this._10 * this._01;
		var b01 = this._00 * this._21 - this._20 * this._01;
		var b02 = this._00 * this._31 - this._30 * this._01;
		var b03 = this._10 * this._21 - this._20 * this._11;
		var b04 = this._10 * this._31 - this._30 * this._11;
		var b05 = this._20 * this._31 - this._30 * this._21;
		var b06 = this._02 * this._13 - this._12 * this._03;
		var b07 = this._02 * this._23 - this._22 * this._03;
		var b08 = this._02 * this._33 - this._32 * this._03;
		var b09 = this._12 * this._23 - this._22 * this._13;
		var b10 = this._12 * this._33 - this._32 * this._13;
		var b11 = this._22 * this._33 - this._32 * this._23;
		return new Mat4(this._11 * b11
			- this._21 * b10
			+ this._31 * b09, this._20 * b10
			- this._10 * b11
			- this._30 * b09,
			this._13 * b05
			- this._23 * b04
			+ this._33 * b03, this._22 * b04
			- this._12 * b05
			- this._32 * b03,
			this._21 * b08
			- this._01 * b11
			- this._31 * b07, this._00 * b11
			- this._20 * b08
			+ this._30 * b07,
			this._23 * b02
			- this._03 * b05
			- this._33 * b01, this._02 * b05
			- this._22 * b02
			+ this._32 * b01,
			this._01 * b10
			- this._11 * b08
			+ this._31 * b06, this._10 * b08
			- this._00 * b10
			- this._30 * b06,
			this._03 * b04
			- this._13 * b02
			+ this._33 * b00, this._12 * b02
			- this._02 * b04
			- this._32 * b00,
			this._11 * b07
			- this._01 * b09
			- this._21 * b06, this._00 * b09
			- this._10 * b07
			+ this._20 * b06,
			this._13 * b01
			- this._03 * b03
			- this._23 * b00, this._02 * b03
			- this._12 * b01
			+ this._22 * b00);
	}

	public inline function toString() {
		return 'mat4(' + '${this._00}, ${this._10}, ${this._20}, ${this._30}, ' + '${this._01}, ${this._11}, ${this._21}, ${this._31}, '
			+ '${this._02}, ${this._12}, ${this._22}, ${this._32}, ' + '${this._03}, ${this._13}, ${this._23}, ${this._33}' + ')';
	}

	@:op(-a)
	static private inline function neg(m:Mat4) {
		return new Mat4(-m._00,
			-m._10,
			-m._20,
			-m._30,
			-m._01,
			-m._11,
			-m._21,
			-m._31,
			-m._02,
			-m._12,
			-m._22,
			-m._32,
			-m._03,
			-m._13,
			-m._23,
			-m._33);
	}

	@:op(++a)
	static private inline function prefixIncrement(m:Mat4) {
		++m._00;
		++m._10;
		++m._20;
		++m._30;
		++m._01;
		++m._11;
		++m._21;
		++m._31;
		++m._02;
		++m._12;
		++m._22;
		++m._32;
		++m._03;
		++m._13;
		++m._23;
		++m._33;
		return m.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(m:Mat4) {
		--m._00;
		--m._10;
		--m._20;
		--m._30;
		--m._01;
		--m._11;
		--m._21;
		--m._31;
		--m._02;
		--m._12;
		--m._22;
		--m._32;
		--m._03;
		--m._13;
		--m._23;
		--m._33;
		return m.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(m:Mat4) {
		var ret = m.clone();
		++m._00;
		++m._10;
		++m._20;
		++m._30;
		++m._01;
		++m._11;
		++m._21;
		++m._31;
		++m._02;
		++m._12;
		++m._22;
		++m._32;
		++m._03;
		++m._13;
		++m._23;
		++m._33;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(m:Mat4) {
		var ret = m.clone();
		--m._00;
		--m._10;
		--m._20;
		--m._30;
		--m._01;
		--m._11;
		--m._21;
		--m._31;
		--m._02;
		--m._12;
		--m._22;
		--m._32;
		--m._03;
		--m._13;
		--m._23;
		--m._33;
		return ret;
	}

	// assignment overload should come before other binary ops to ensure they have priority

	@:op(a *= b)
	static private inline function mulEq(a:Mat4, b:Mat4):Mat4
		return a.copyFrom(a * b);

	@:op(a *= b)
	static private inline function mulEqScalar(a:Mat4, f:Float):Mat4
		return a.copyFrom(a * f);

	@:op(a /= b)
	static private inline function divEq(a:Mat4, b:Mat4):Mat4
		return a.copyFrom(a / b);

	@:op(a /= b)
	static private inline function divEqScalar(a:Mat4, f:Float):Mat4
		return a.copyFrom(a / f);

	@:op(a += b)
	static private inline function addEq(a:Mat4, b:Mat4):Mat4
		return a.copyFrom(a + b);

	@:op(a += b)
	static private inline function addEqScalar(a:Mat4, f:Float):Mat4
		return a.copyFrom(a + f);

	@:op(a -= b)
	static private inline function subEq(a:Mat4, b:Mat4):Mat4
		return a.copyFrom(a - b);

	@:op(a -= b)
	static private inline function subEqScalar(a:Mat4, f:Float):Mat4
		return a.copyFrom(a - f);

	@:op(a + b)
	static private inline function add(m:Mat4, n:Mat4):Mat4 {
		return new Mat4(m._00
			+ n._00, m._10
			+ n._10, m._20
			+ n._20, m._30
			+ n._30, m._01
			+ n._01, m._11
			+ n._11, m._21
			+ n._21, m._31
			+ n._31, m._02
			+ n._02,
			m._12
			+ n._12, m._22
			+ n._22, m._32
			+ n._32, m._03
			+ n._03, m._13
			+ n._13, m._23
			+ n._23, m._33
			+ n._33);
	}

	@:op(a + b) @:commutative
	static private inline function addScalar(m:Mat4, f:Float):Mat4 {
		return new Mat4(m._00
			+ f, m._10
			+ f, m._20
			+ f, m._30
			+ f, m._01
			+ f, m._11
			+ f, m._21
			+ f, m._31
			+ f, m._02
			+ f, m._12
			+ f, m._22
			+ f, m._32
			+ f,
			m._03
			+ f, m._13
			+ f, m._23
			+ f, m._33
			+ f);
	}

	@:op(a - b)
	static private inline function sub(m:Mat4, n:Mat4):Mat4 {
		return new Mat4(m._00
			- n._00, m._10
			- n._10, m._20
			- n._20, m._30
			- n._30, m._01
			- n._01, m._11
			- n._11, m._21
			- n._21, m._31
			- n._31, m._02
			- n._02,
			m._12
			- n._12, m._22
			- n._22, m._32
			- n._32, m._03
			- n._03, m._13
			- n._13, m._23
			- n._23, m._33
			- n._33);
	}

	@:op(a - b)
	static private inline function subScalar(m:Mat4, f:Float):Mat4 {
		return new Mat4(m._00
			- f, m._10
			- f, m._20
			- f, m._30
			- f, m._01
			- f, m._11
			- f, m._21
			- f, m._31
			- f, m._02
			- f, m._12
			- f, m._22
			- f, m._32
			- f,
			m._03
			- f, m._13
			- f, m._23
			- f, m._33
			- f);
	}

	@:op(a - b)
	static private inline function subScalarInv(f:Float, m:Mat4):Mat4 {
		return new Mat4(f
			- m._00, f
			- m._10, f
			- m._20, f
			- m._30, f
			- m._01, f
			- m._11, f
			- m._21, f
			- m._31, f
			- m._02, f
			- m._12, f
			- m._22, f
			- m._32,
			f
			- m._03, f
			- m._13, f
			- m._23, f
			- m._33);
	}

	@:op(a * b)
	static private inline function mul(m:Mat4, n:Mat4):Mat4 {
		return new Mat4(m._00 * n._00
			+ m._01 * n._10
			+ m._02 * n._20
			+ m._03 * n._30, m._10 * n._00
			+ m._11 * n._10
			+ m._12 * n._20
			+ m._13 * n._30,
			m._20 * n._00
			+ m._21 * n._10
			+ m._22 * n._20
			+ m._23 * n._30, m._30 * n._00
			+ m._31 * n._10
			+ m._32 * n._20
			+ m._33 * n._30,
			m._00 * n._01
			+ m._01 * n._11
			+ m._02 * n._21
			+ m._03 * n._31, m._10 * n._01
			+ m._11 * n._11
			+ m._12 * n._21
			+ m._13 * n._31,
			m._20 * n._01
			+ m._21 * n._11
			+ m._22 * n._21
			+ m._23 * n._31, m._30 * n._01
			+ m._31 * n._11
			+ m._32 * n._21
			+ m._33 * n._31,
			m._00 * n._02
			+ m._01 * n._12
			+ m._02 * n._22
			+ m._03 * n._32, m._10 * n._02
			+ m._11 * n._12
			+ m._12 * n._22
			+ m._13 * n._32,
			m._20 * n._02
			+ m._21 * n._12
			+ m._22 * n._22
			+ m._23 * n._32, m._30 * n._02
			+ m._31 * n._12
			+ m._32 * n._22
			+ m._33 * n._32,
			m._00 * n._03
			+ m._01 * n._13
			+ m._02 * n._23
			+ m._03 * n._33, m._10 * n._03
			+ m._11 * n._13
			+ m._12 * n._23
			+ m._13 * n._33,
			m._20 * n._03
			+ m._21 * n._13
			+ m._22 * n._23
			+ m._23 * n._33, m._30 * n._03
			+ m._31 * n._13
			+ m._32 * n._23
			+ m._33 * n._33);
	}

	@:op(a * b)
	static private inline function postMulVec4(m:Mat4, v:Vec4):Vec4 {
		return new Vec4(m._00 * v.x
			+ m._01 * v.y
			+ m._02 * v.z
			+ m._03 * v.w, m._10 * v.x
			+ m._11 * v.y
			+ m._12 * v.z
			+ m._13 * v.w,
			m._20 * v.x
			+ m._21 * v.y
			+ m._22 * v.z
			+ m._23 * v.w, m._30 * v.x
			+ m._31 * v.y
			+ m._32 * v.z
			+ m._33 * v.w);
	}

	@:op(a * b)
	static private inline function preMulVec4(v:Vec4, m:Mat4):Vec4 {
		return new Vec4(v.dot(new Vec4(m._00, m._10, m._20, m._30)), v.dot(new Vec4(m._01, m._11, m._21, m._31)), v.dot(new Vec4(m._02, m._12, m._22, m._32)),
			v.dot(new Vec4(m._03, m._13, m._23, m._33)));
	}

	@:op(a * b) @:commutative
	static private inline function mulScalar(m:Mat4, f:Float):Mat4 {
		return new Mat4(m._00 * f, m._10 * f, m._20 * f, m._30 * f, m._01 * f, m._11 * f, m._21 * f, m._31 * f, m._02 * f, m._12 * f, m._22 * f, m._32 * f,
			m._03 * f, m._13 * f, m._23 * f, m._33 * f);
	}

	@:op(a / b)
	static private inline function div(m:Mat4, n:Mat4):Mat4
		return m.matrixCompMult(1.0 / n);

	@:op(a / b)
	static private inline function divScalar(m:Mat4, f:Float):Mat4 {
		return new Mat4(m._00 / f, m._10 / f, m._20 / f, m._30 / f, m._01 / f, m._11 / f, m._21 / f, m._31 / f, m._02 / f, m._12 / f, m._22 / f, m._32 / f,
			m._03 / f, m._13 / f, m._23 / f, m._33 / f);
	}

	@:op(a / b)
	static private inline function divScalarInv(f:Float, m:Mat4):Mat4 {
		return new Mat4(f / m._00, f / m._10, f / m._20, f / m._30, f / m._01, f / m._11, f / m._21, f / m._31, f / m._02, f / m._12, f / m._22, f / m._32,
			f / m._03, f / m._13, f / m._23, f / m._33);
	}

	@:op(a == b)
	static private inline function equal(m:Mat4, n:Mat4):Bool {
		return m._00 == n._00 && m._10 == n._10 && m._20 == n._20 && m._30 == n._30 && m._01 == n._01 && m._11 == n._11 && m._21 == n._21 && m._31 == n._31
			&& m._02 == n._02 && m._12 == n._12 && m._22 == n._22 && m._32 == n._32 && m._03 == n._03 && m._13 == n._13 && m._23 == n._23 && m._33 == n._33;
	}

	@:op(a != b)
	static private inline function notEqual(m:Mat4, n:Mat4):Bool
		return !equal(m, n);

	/**
		Copies matrix elements in column-major order into a type that supports array-write access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:haxe.macro.Expr.ExprOf<Mat4>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyIntoArray(array, i);
			self[1].copyIntoArray(array, i + 4);
			self[2].copyIntoArray(array, i + 8);
			self[3].copyIntoArray(array, i + 12);
			array;
		}
	}

	/**
		Copies matrix elements in column-major order from a type that supports array-read access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):Mat4 {})
	public macro function copyFromArray(self:haxe.macro.Expr.ExprOf<Mat4>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyFromArray(array, i);
			self[1].copyFromArray(array, i + 4);
			self[2].copyFromArray(array, i + 8);
			self[3].copyFromArray(array, i + 12);
			self;
		}
	}

	// static macros

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>):ExprOf<Mat4> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Mat4(array[0 + i], array[1 + i], array[2 + i], array[3 + i], array[4 + i], array[5 + i], array[6 + i], array[7 + i], array[8 + i],
				array[9 + i], array[10 + i], array[11 + i], array[12 + i], array[13 + i], array[14 + i], array[15 + i]);
		}
	}
}
