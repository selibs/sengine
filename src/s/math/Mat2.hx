package s.math;

import kha.math.FastMatrix2 as KhaMat2;

@:nullSafety
@:forward.new
@:forward(_00, _10, _01, _11)
extern abstract Mat2(KhaMat2) from KhaMat2 to KhaMat2 {
	public inline function set(a00:Float, a10:Float, a01:Float, a11:Float) {
		this._00 = a00;
		this._10 = a10;
		this._01 = a01;
		this._11 = a11;
	}

	public inline function copyFrom(v:Mat2) {
		this.setFrom(v);
		return this;
	}

	public inline function clone():Mat2 {
		return new Mat2(this._00, this._10, this._01, this._11);
	}

	public inline function matrixCompMult(n:Mat2):Mat2 {
		return new Mat2(this._00 * n._00, this._10 * n._10, this._01 * n._01, this._11 * n._11);
	}

	// extended methods

	public inline function transpose():Mat2 {
		return new Mat2(this._00, this._01, this._10, this._11);
	}

	public inline function determinant():Float {
		return this._00 * this._11 - this._01 * this._10;
	}

	public inline function inverse():Mat2 {
		var f = 1.0 / determinant();
		return new Mat2(this._11 * f, -this._10 * f, -this._01 * f, this._00 * f);
	}

	public inline function adjoint():Mat2 {
		return new Mat2(this._11, -this._10, -this._01, this._00);
	}

	public inline function toString() {
		return 'mat2(' + '${this._00}, ${this._10}, ' + '${this._01}, ${this._11}' + ')';
	}

	@:op(-a)
	static private inline function neg(m:Mat2) {
		return new Mat2(-m._00, -m._10, -m._01, -m._11);
	}

	@:op(++a)
	static private inline function prefixIncrement(m:Mat2) {
		++m._00;
		++m._10;
		++m._01;
		++m._11;
		return m.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(m:Mat2) {
		--m._00;
		--m._10;
		--m._01;
		--m._11;
		return m.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(m:Mat2) {
		var ret = m.clone();
		++m._00;
		++m._10;
		++m._01;
		++m._11;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(m:Mat2) {
		var ret = m.clone();
		--m._00;
		--m._10;
		--m._01;
		--m._11;
		return ret;
	}

	// assignment overload should come before other binary ops to ensure they have priority

	@:op(a *= b)
	static private inline function mulEq(a:Mat2, b:Mat2):Mat2
		return a.copyFrom(a * b);

	@:op(a *= b)
	static private inline function mulEqScalar(a:Mat2, f:Float):Mat2
		return a.copyFrom(mulScalar(a, f));

	@:op(a /= b)
	static private inline function divEq(a:Mat2, b:Mat2):Mat2
		return a.copyFrom(a / b);

	@:op(a /= b)
	static private inline function divEqScalar(a:Mat2, f:Float):Mat2
		return a.copyFrom(a / f);

	@:op(a += b)
	static private inline function addEq(a:Mat2, b:Mat2):Mat2
		return a.copyFrom(a + b);

	@:op(a += b)
	static private inline function addEqScalar(a:Mat2, f:Float):Mat2
		return a.copyFrom(a + f);

	@:op(a -= b)
	static private inline function subEq(a:Mat2, b:Mat2):Mat2
		return a.copyFrom(a - b);

	@:op(a -= b)
	static private inline function subEqScalar(a:Mat2, f:Float):Mat2
		return a.copyFrom(a - f);

	@:op(a + b)
	static private inline function add(m:Mat2, n:Mat2):Mat2 {
		return new Mat2(m._00 + n._00, m._10 + n._10, m._01 + n._01, m._11 + n._11);
	}

	@:op(a + b) @:commutative
	static private inline function addScalar(m:Mat2, f:Float):Mat2 {
		return new Mat2(m._00 + f, m._10 + f, m._01 + f, m._11 + f);
	}

	@:op(a - b)
	static private inline function sub(m:Mat2, n:Mat2):Mat2 {
		return new Mat2(m._00 - n._00, m._10 - n._10, m._01 - n._01, m._11 - n._11);
	}

	@:op(a - b)
	static private inline function subScalar(m:Mat2, f:Float):Mat2 {
		return new Mat2(m._00 - f, m._10 - f, m._01 - f, m._11 - f);
	}

	@:op(a - b)
	static private inline function subScalarInv(f:Float, m:Mat2):Mat2 {
		return new Mat2(f - m._00, f - m._10, f - m._01, f - m._11);
	}

	@:op(a * b)
	static private inline function mul(m:Mat2, n:Mat2):Mat2 {
		return new Mat2(m._00 * n._00
			+ m._01 * n._10, m._10 * n._00
			+ m._11 * n._10, m._00 * n._01
			+ m._01 * n._11, m._10 * n._01
			+ m._11 * n._11);
	}

	@:op(a * b)
	static private inline function postMulVec2(m:Mat2, v:Vec2):Vec2 {
		return new Vec2(m._00 * v.x + m._01 * v.y, m._10 * v.x + m._11 * v.y);
	}

	@:op(a * b)
	static private inline function preMulVec2(v:Vec2, m:Mat2):Vec2 {
		return new Vec2(v.dot(new Vec2(m._00, m._10)), v.dot(new Vec2(m._01, m._11)));
	}

	@:op(a * b) @:commutative
	static private inline function mulScalar(m:Mat2, f:Float):Mat2 {
		return new Mat2(m._00 * f, m._10 * f, m._01 * f, m._11 * f);
	}

	@:op(a / b)
	static private inline function div(m:Mat2, n:Mat2):Mat2 {
		return m.matrixCompMult(1.0 / n);
	}

	@:op(a / b)
	static private inline function divScalar(m:Mat2, f:Float):Mat2 {
		return new Mat2(m._00 / f, m._10 / f, m._01 / f, m._11 / f);
	}

	@:op(a / b)
	static private inline function divScalarInv(f:Float, m:Mat2):Mat2 {
		return new Mat2(f / m._00, f / m._10, f / m._01, f / m._11);
	}

	@:op(a == b)
	static private inline function equal(m:Mat2, n:Mat2):Bool {
		return m._00 == n._00 && m._10 == n._10 && m._01 == n._01 && m._11 == n._11;
	}

	@:op(a != b)
	static private inline function notEqual(m:Mat2, n:Mat2):Bool
		return !equal(m, n);

	/**
		Copies matrix elements in column-major order into a type that supports array-write access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:haxe.macro.Expr.ExprOf<Mat2>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyIntoArray(array, i);
			self[1].copyIntoArray(array, i + 2);
			array;
		}
	}

	/**
		Copies matrix elements in column-major order from a type that supports array-read access
	**/
	@:overload(function<T>(arrayLike:T, index:Int):Mat2 {})
	public macro function copyFromArray(self:haxe.macro.Expr.ExprOf<Mat2>, array:haxe.macro.Expr.ExprOf<ArrayAccess<Float>>,
			index:haxe.macro.Expr.ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self[0].copyFromArray(array, i);
			self[1].copyFromArray(array, i + 2);
			self;
		}
	}

	// static macros

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>):ExprOf<Mat2> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Mat2(array[0 + i], array[1 + i], array[2 + i], array[3 + i]);
		}
	}
}
