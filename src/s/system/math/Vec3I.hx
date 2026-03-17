package s.system.math;

#if macro
import haxe.macro.Expr.ExprOf;
#end

@:nullSafety
@:forward.new
@:forward(x, y, z)
extern abstract Vec3I(Vec3IData) from Vec3IData to Vec3IData {
	#if !macro
	@:from
	public static inline function fromVec3(value:Vec3):Vec3I {
		return new Vec3I(Std.int(value.x), Std.int(value.y), Std.int(value.z));
	}

	public inline function set(x:Int, y:Int, z:Int) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function clone() {
		return new Vec3I(this.x, this.y, this.z);
	}

	public inline function toString() {
		return 'vec3(${this.x}, ${this.y}, ${this.z})';
	}

	@:op([])
	private inline function arrayRead(i:Int)
		return switch i {
			case 0: this.x;
			case 1: this.y;
			case 2: this.z;
			default: null;
		}

	@:op([])
	private inline function arrayWrite(i:Int, v:Int)
		return switch i {
			case 0: this.x = v;
			case 1: this.y = v;
			case 2: this.z = v;
			default: null;
		}

	@:op(-a)
	static private inline function neg(a:Vec3I)
		return new Vec3I(-a.x, -a.y, -a.z);

	@:op(++a)
	static private inline function prefixIncrement(a:Vec3I) {
		++a.x;
		++a.y;
		++a.z;
		return a.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(a:Vec3I) {
		--a.x;
		--a.y;
		--a.z;
		return a.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(a:Vec3I) {
		var ret = a.clone();
		++a.x;
		++a.y;
		++a.z;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(a:Vec3I) {
		var ret = a.clone();
		--a.x;
		--a.y;
		--a.z;
		return ret;
	}

	@:op(a * b)
	static private inline function mul(a:Vec3I, b:Vec3I):Vec3I
		return new Vec3I(a.x * b.x, a.y * b.y, a.z * b.z);

	@:op(a * b) @:commutative
	static private inline function mulScalar(a:Vec3I, b:Int):Vec3I
		return new Vec3I(a.x * b, a.y * b, a.z * b);

	@:op(a / b)
	static private inline function div(a:Vec3I, b:Vec3I):Vec3I
		return new Vec3(a.x / b.x, a.y / b.y, a.z / b.z);

	@:op(a / b)
	static private inline function divScalar(a:Vec3I, b:Int):Vec3I
		return new Vec3(a.x / b, a.y / b, a.z / b);

	@:op(a / b)
	static private inline function divScalarInv(a:Int, b:Vec3I):Vec3I
		return new Vec3(a / b.x, a / b.y, a / b.z);

	@:op(a + b)
	static private inline function add(a:Vec3I, b:Vec3I):Vec3I
		return new Vec3I(a.x + b.x, a.y + b.y, a.z + b.z);

	@:op(a + b) @:commutative
	static private inline function addScalar(a:Vec3I, b:Int):Vec3I
		return new Vec3I(a.x + b, a.y + b, a.z + b);

	@:op(a - b)
	static private inline function sub(a:Vec3I, b:Vec3I):Vec3I
		return new Vec3I(a.x - b.x, a.y - b.y, a.z - b.z);

	@:op(a - b)
	static private inline function subScalar(a:Vec3I, b:Int):Vec3I
		return new Vec3I(a.x - b, a.y - b, a.z - b);

	@:op(b - a)
	static private inline function subScalarInv(a:Int, b:Vec3I):Vec3I
		return new Vec3I(a - b.x, a - b.y, a - b.z);

	@:op(a == b)
	static private inline function equal(a:Vec3I, b:Vec3I):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z;

	@:op(a != b)
	static private inline function notEqual(a:Vec3I, b:Vec3I):Bool
		return !equal(a, b);
	#end // !macro

	// macros

	/**
	 * Copy from any object with .x .y .z fields
	 */
	@:overload(function(source:{x:Int, y:Int, z:Int}):Vec3I {})
	public macro function copyFrom(self:ExprOf<Vec3I>, source:ExprOf<{x:Int, y:Int, z:Int}>):ExprOf<Vec3I> {
		return macro {
			var self = $self;
			var source = $source;
			self.x = source.x;
			self.y = source.y;
			self.z = source.z;
			self;
		}
	}

	/**
	 * Copy into any object with .x .y .z fields
	 */
	@:overload(function(target:{x:Int, y:Int, z:Int}):{x:Int, y:Int, z:Int} {})
	public macro function copyInto(self:ExprOf<Vec3I>, target:ExprOf<{x:Int, y:Int, z:Int}>):ExprOf<{x:Int, y:Int, z:Int}> {
		return macro {
			var self = $self;
			var target = $target;
			target.x = self.x;
			target.y = self.y;
			target.z = self.z;
			target;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:ExprOf<Vec3I>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			array[0 + i] = self.x;
			array[1 + i] = self.y;
			array[2 + i] = self.z;
			array;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyFromArray(self:ExprOf<Vec3I>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self.x = array[0 + i];
			self.y = array[1 + i];
			self.z = array[2 + i];
			self;
		}
	}

	// static macros

	/**
	 * Create from any object with .x .y .z fields
	 */
	@:overload(function(source:{x:Int, y:Int, z:Int}):Vec3I {})
	public static macro function from(xyz:ExprOf<{x:Int, y:Int, z:Int}>):ExprOf<Vec3I> {
		return macro {
			var source = $xyz;
			new Vec3I(source.x, source.y, source.z);
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>):ExprOf<Vec3I> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Vec3I(array[0 + i], array[1 + i], array[2 + i]);
		}
	}
}

private class Vec3IData {
	public var x:Int;
	public var y:Int;
	public var z:Int;

	public inline function new(x:Int = 0, y:Int = 0, z:Int = 0):Void {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}
