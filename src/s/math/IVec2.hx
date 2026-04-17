package s.math;

@:nullSafety
@:forward.new
@:forward(x, y)
extern abstract IVec2(IVec2Data) from IVec2Data to IVec2Data {
	#if !macro
	@:from
	public static inline function fromVec2(value:Vec2):IVec2
		return new IVec2(Std.int(value.x), Std.int(value.y));

	public inline function set(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}

	public inline function clone()
		return new IVec2(this.x, this.y);

	public inline function toString()
		return 'vec2(${this.x}, ${this.y})';

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
	static private inline function neg(a:IVec2)
		return new IVec2(-a.x, -a.y);

	@:op(++a)
	static private inline function prefixIncrement(a:IVec2) {
		++a.x;
		++a.y;
		return a.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(a:IVec2) {
		--a.x;
		--a.y;
		return a.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(a:IVec2) {
		var ret = a.clone();
		++a.x;
		++a.y;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(a:IVec2) {
		var ret = a.clone();
		--a.x;
		--a.y;
		return ret;
	}

	@:op(a * b)
	static private inline function mul(a:IVec2, b:IVec2):IVec2
		return new IVec2(a.x * b.x, a.y * b.y);

	@:op(a * b) @:commutative
	static private inline function mulScalar(a:IVec2, b:Int):IVec2
		return new IVec2(a.x * b, a.y * b);

	@:op(a / b)
	static private inline function div(a:IVec2, b:IVec2):IVec2
		return new Vec2(a.x / b.x, a.y / b.y);

	@:op(a / b)
	static private inline function divScalar(a:IVec2, b:Int):IVec2
		return new Vec2(a.x / b, a.y / b);

	@:op(a / b)
	static private inline function divScalarInv(a:Int, b:IVec2):IVec2
		return new Vec2(a / b.x, a / b.y);

	@:op(a + b)
	static private inline function add(a:IVec2, b:IVec2):IVec2
		return new IVec2(a.x + b.x, a.y + b.y);

	@:op(a + b) @:commutative
	static private inline function addScalar(a:IVec2, b:Int):IVec2
		return new IVec2(a.x + b, a.y + b);

	@:op(a - b)
	static private inline function sub(a:IVec2, b:IVec2):IVec2
		return new IVec2(a.x - b.x, a.y - b.y);

	@:op(a - b)
	static private inline function subScalar(a:IVec2, b:Int):IVec2
		return new IVec2(a.x - b, a.y - b);

	@:op(b - a)
	static private inline function subScalarInv(a:Int, b:IVec2):IVec2
		return new IVec2(a - b.x, a - b.y);

	@:op(a == b)
	static private inline function equal(a:IVec2, b:IVec2):Bool
		return a.x == b.x && a.y == b.y;

	@:op(a != b)
	static private inline function notEqual(a:IVec2, b:IVec2):Bool
		return !equal(a, b);
	#end // !macro

	// macros

	/**
	 * Copy from any object with .x .y fields
	 */
	@:overload(function(source:{x:Int, y:Int}):IVec2 {})
	public macro function copyFrom(self:ExprOf<IVec2>, source:ExprOf<{x:Int, y:Int}>):ExprOf<IVec2>
		return macro {
			var self = $self;
			var source = $source;
			self.x = source.x;
			self.y = source.y;
			self;
		}

	/**
	 * Copy into any object with .x .y fields
	 */
	@:overload(function(target:{x:Int, y:Int}):{x:Int, y:Int} {})
	public macro function copyInto(self:ExprOf<IVec2>, target:ExprOf<{x:Int, y:Int}>):ExprOf<{x:Int, y:Int}>
		return macro {
			var self = $self;
			var target = $target;
			target.x = self.x;
			target.y = self.y;
			target;
		}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:ExprOf<IVec2>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>)
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			array[0 + i] = self.x;
			array[1 + i] = self.y;
			array;
		}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyFromArray(self:ExprOf<IVec2>, array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>)
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self.x = array[0 + i];
			self.y = array[1 + i];
			self;
		}

	// static macros

	/**
	 * Create from any object with .x .y fields
	 */
	@:overload(function(source:{x:Int, y:Int}):IVec2 {})
	public static macro function from(xy:ExprOf<{x:Int, y:Int}>):ExprOf<IVec2>
		return macro {
			var source = $xy;
			new IVec2(source.x, source.y);
		}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Int>>, index:ExprOf<Int>):ExprOf<IVec2>
		return macro {
			var array = $array;
			var i:Int = $index;
			new IVec2(array[0 + i], array[1 + i]);
		}
}

private class IVec2Data {
	public var x:Int;
	public var y:Int;

	public inline function new(x:Int = 0, y:Int = 0):Void {
		this.x = x;
		this.y = y;
	}
}
