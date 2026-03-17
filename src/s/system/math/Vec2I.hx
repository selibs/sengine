package s.system.math;

@:nullSafety
@:forward.new
@:forward(x, y)
extern abstract Vec2I(Vec2IData) from Vec2IData to Vec2IData {
	#if !macro
	@:from
	public static inline function fromVec2(value:Vec2):Vec2I {
		return new Vec2I(Std.int(value.x), Std.int(value.y));
	}

	public inline function set(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}

	public inline function clone() {
		return new Vec2I(this.x, this.y);
	}

	public inline function toString() {
		return 'vec2(${this.x}, ${this.y})';
	}

	@:op([])
	private inline function arrayRead(i:Int)
		return switch i {
			case 0: this.x;
			case 1: this.y;
			default: null;
		}

	@:op([])
	private inline function arrayWrite(i:Int, v:Int)
		return switch i {
			case 0: this.x = v;
			case 1: this.y = v;
			default: null;
		}

	@:op(-a)
	static private inline function neg(a:Vec2I)
		return new Vec2I(-a.x, -a.y);

	@:op(++a)
	static private inline function prefixIncrement(a:Vec2I) {
		++a.x;
		++a.y;
		return a.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(a:Vec2I) {
		--a.x;
		--a.y;
		return a.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(a:Vec2I) {
		var ret = a.clone();
		++a.x;
		++a.y;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(a:Vec2I) {
		var ret = a.clone();
		--a.x;
		--a.y;
		return ret;
	}

	@:op(a * b)
	static private inline function mul(a:Vec2I, b:Vec2I):Vec2I
		return new Vec2I(a.x * b.x, a.y * b.y);

	@:op(a * b) @:commutative
	static private inline function mulScalar(a:Vec2I, b:Int):Vec2I
		return new Vec2I(a.x * b, a.y * b);

	@:op(a / b)
	static private inline function div(a:Vec2I, b:Vec2I):Vec2I
		return new Vec2(a.x / b.x, a.y / b.y);

	@:op(a / b)
	static private inline function divScalar(a:Vec2I, b:Int):Vec2I
		return new Vec2(a.x / b, a.y / b);

	@:op(a / b)
	static private inline function divScalarInv(a:Int, b:Vec2I):Vec2I
		return new Vec2(a / b.x, a / b.y);

	@:op(a + b)
	static private inline function add(a:Vec2I, b:Vec2I):Vec2I
		return new Vec2I(a.x + b.x, a.y + b.y);

	@:op(a + b) @:commutative
	static private inline function addScalar(a:Vec2I, b:Int):Vec2I
		return new Vec2I(a.x + b, a.y + b);

	@:op(a - b)
	static private inline function sub(a:Vec2I, b:Vec2I):Vec2I
		return new Vec2I(a.x - b.x, a.y - b.y);

	@:op(a - b)
	static private inline function subScalar(a:Vec2I, b:Int):Vec2I
		return new Vec2I(a.x - b, a.y - b);

	@:op(b - a)
	static private inline function subScalarInv(a:Int, b:Vec2I):Vec2I
		return new Vec2I(a - b.x, a - b.y);

	@:op(a == b)
	static private inline function equal(a:Vec2I, b:Vec2I):Bool
		return a.x == b.x && a.y == b.y;

	@:op(a != b)
	static private inline function notEqual(a:Vec2I, b:Vec2I):Bool
		return !equal(a, b);
	#end // !macro

	// macros

	/**
	 * Copy from any object with .x .y fields
	 */
	@:overload(function(source:{x:Int, y:Int}):Vec2I {})
	public macro function copyFrom(self:ExprOf<Vec2I>, source:ExprOf<{x:Int, y:Int}>):ExprOf<Vec2I> {
		return macro {
			var self = $self;
			var source = $source;
			self.x = source.x;
			self.y = source.y;
			self;
		}
	}

	/**
	 * Copy into any object with .x .y fields
	 */
	@:overload(function(target:{x:Int, y:Int}):{x:Int, y:Int} {})
	public macro function copyInto(self:ExprOf<Vec2I>, target:ExprOf<{x:Int, y:Int}>):ExprOf<{x:Int, y:Int}> {
		return macro {
			var self = $self;
			var target = $target;
			target.x = self.x;
			target.y = self.y;
			target;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:ExprOf<Vec2I>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			array[0 + i] = self.x;
			array[1 + i] = self.y;
			array;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyFromArray(self:ExprOf<Vec2I>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self.x = array[0 + i];
			self.y = array[1 + i];
			self;
		}
	}

	// static macros

	/**
	 * Create from any object with .x .y fields
	 */
	@:overload(function(source:{x:Int, y:Int}):Vec2I {})
	public static macro function from(xy:ExprOf<{x:Int, y:Int}>):ExprOf<Vec2I> {
		return macro {
			var source = $xy;
			new Vec2I(source.x, source.y);
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>):ExprOf<Vec2I> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Vec2I(array[0 + i], array[1 + i]);
		}
	}
}

private class Vec2IData {
	public var x:Int;
	public var y:Int;

	public inline function new(x:Int = 0, y:Int = 0):Void {
		this.x = x;
		this.y = y;
	}
}
