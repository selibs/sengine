package s.system.math;

#if macro
import haxe.macro.Expr.ExprOf;
#end
import kha.math.FastVector3 as KhaVec3;

@:nullSafety
@:forward.new
@:forward(x, y, z) #if !macro @:build(s.system.math.SMath.Swizzle.generateFields(3)) #end
extern abstract Vec3(KhaVec3) from KhaVec3 to KhaVec3 {
	#if !macro
	@:to
	public inline function toVec3I():Vec3I {
		return Vec3I.fromVec3(this);
	}

	public inline function set(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function clone() {
		return new Vec3(this.x, this.y, this.z);
	}

	// special case for vec3
	public inline function cross(b:Vec3)
		return new Vec3(this.y * b.z - this.z * b.y, this.z * b.x - this.x * b.z, this.x * b.y - this.y * b.x);

	// Trigonometric
	public inline function radians():Vec3 {
		return (this : Vec3) * Math.PI / 180;
	}

	public inline function degrees():Vec3 {
		return (this : Vec3) * 180 / Math.PI;
	}

	public inline function sin():Vec3 {
		return new Vec3(Math.sin(this.x), Math.sin(this.y), Math.sin(this.z));
	}

	public inline function cos():Vec3 {
		return new Vec3(Math.cos(this.x), Math.cos(this.y), Math.cos(this.z));
	}

	public inline function tan():Vec3 {
		return new Vec3(Math.tan(this.x), Math.tan(this.y), Math.tan(this.z));
	}

	public inline function asin():Vec3 {
		return new Vec3(Math.asin(this.x), Math.asin(this.y), Math.asin(this.z));
	}

	public inline function acos():Vec3 {
		return new Vec3(Math.acos(this.x), Math.acos(this.y), Math.acos(this.z));
	}

	public inline function atan():Vec3 {
		return new Vec3(Math.atan(this.x), Math.atan(this.y), Math.atan(this.z));
	}

	public inline function atan2(b:Vec3):Vec3 {
		return new Vec3(Math.atan2(this.x, b.x), Math.atan2(this.y, b.y), Math.atan2(this.z, b.z));
	}

	// Exponential
	public inline function pow(e:Vec3):Vec3 {
		return new Vec3(Math.pow(this.x, e.x), Math.pow(this.y, e.y), Math.pow(this.z, e.z));
	}

	public inline function exp():Vec3 {
		return new Vec3(Math.exp(this.x), Math.exp(this.y), Math.exp(this.z));
	}

	public inline function log():Vec3 {
		return new Vec3(Math.log(this.x), Math.log(this.y), Math.log(this.z));
	}

	public inline function exp2():Vec3 {
		return new Vec3(Math.pow(2, this.x), Math.pow(2, this.y), Math.pow(2, this.z));
	}

	public inline function log2():Vec3 @:privateAccess {
		return new Vec3(SMath.log2f(this.x), SMath.log2f(this.y), SMath.log2f(this.z));
	}

	public inline function sqrt():Vec3 {
		return new Vec3(Math.sqrt(this.x), Math.sqrt(this.y), Math.sqrt(this.z));
	}

	public inline function inverseSqrt():Vec3 {
		return 1.0 / sqrt();
	}

	// Common
	public inline function abs():Vec3 {
		return new Vec3(Math.abs(this.x), Math.abs(this.y), Math.abs(this.z));
	}

	public inline function sign():Vec3 {
		return new Vec3(this.x > 0.?1.:(this.x < 0.? -1.:0.), this.y > 0.?1.:(this.y < 0.? -1.:0.), this.z > 0.?1.:(this.z < 0.? -1.:0.));
	}

	public inline function floor():Vec3 {
		return new Vec3(Math.floor(this.x), Math.floor(this.y), Math.floor(this.z));
	}

	public inline function ceil():Vec3 {
		return new Vec3(Math.ceil(this.x), Math.ceil(this.y), Math.ceil(this.z));
	}

	public inline function fract():Vec3 {
		return (this : Vec3) - floor();
	}

	extern overload public inline function mod(d:Vec3):Vec3 {
		return (this : Vec3) - d * ((this : Vec3) / d).floor();
	}

	extern overload public inline function mod(d:Float):Vec3 {
		return (this : Vec3) - d * ((this : Vec3) / d).floor();
	}

	extern overload public inline function min(b:Vec3):Vec3 {
		return new Vec3(b.x < this.x ? b.x : this.x, b.y < this.y ? b.y : this.y, b.z < this.z ? b.z : this.z);
	}

	extern overload public inline function min(b:Float):Vec3 {
		return new Vec3(b < this.x ? b : this.x, b < this.y ? b : this.y, b < this.z ? b : this.z);
	}

	extern overload public inline function max(b:Vec3):Vec3 {
		return new Vec3(this.x < b.x ? b.x : this.x, this.y < b.y ? b.y : this.y, this.z < b.z ? b.z : this.z);
	}

	extern overload public inline function max(b:Float):Vec3 {
		return new Vec3(this.x < b ? b : this.x, this.y < b ? b : this.y, this.z < b ? b : this.z);
	}

	extern overload public inline function clamp(minLimit:Vec3, maxLimit:Vec3) {
		return max(minLimit).min(maxLimit);
	}

	extern overload public inline function clamp(minLimit:Float, maxLimit:Float) {
		return max(minLimit).min(maxLimit);
	}

	extern overload public inline function mix(b:Vec3, t:Vec3):Vec3 {
		return (this : Vec3) * (1.0 - t) + b * t;
	}

	extern overload public inline function mix(b:Vec3, t:Float):Vec3 {
		return (this : Vec3) * (1.0 - t) + b * t;
	}

	extern overload public inline function step(edge:Vec3):Vec3 {
		return new Vec3(this.x < edge.x ? 0.0 : 1.0, this.y < edge.y ? 0.0 : 1.0, this.z < edge.z ? 0.0 : 1.0);
	}

	extern overload public inline function step(edge:Float):Vec3 {
		return new Vec3(this.x < edge ? 0.0 : 1.0, this.y < edge ? 0.0 : 1.0, this.z < edge ? 0.0 : 1.0);
	}

	extern overload public inline function smoothstep(edge0:Vec3, edge1:Vec3):Vec3 {
		var t = (((this : Vec3) - edge0) / (edge1 - edge0)).clamp(0, 1);
		return t * t * (3.0 - 2.0 * t);
	}

	extern overload public inline function smoothstep(edge0:Float, edge1:Float):Vec3 {
		var t = (((this : Vec3) - edge0) / (edge1 - edge0)).clamp(0, 1);
		return t * t * (3.0 - 2.0 * t);
	}

	// Geometric
	public inline function length():Float {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}

	public inline function distance(b:Vec3):Float {
		return (b - this).length();
	}

	public inline function dot(b:Vec3):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z;
	}

	public inline function normalize():Vec3 {
		var v:Vec3 = this;
		var lenSq = v.dot(this);
		var denominator = lenSq == 0.0 ? 1.0 : Math.sqrt(lenSq); // for 0 length, return zero vector rather than infinity
		return v / denominator;
	}

	public inline function faceforward(I:Vec3, Nref:Vec3):Vec3 {
		return new Vec3(this.x, this.y, this.z) * (Nref.dot(I) < 0 ? 1 : -1);
	}

	public inline function reflect(N:Vec3):Vec3 {
		var I = (this : Vec3);
		return I - 2 * N.dot(I) * N;
	}

	public inline function refract(N:Vec3, eta:Float):Vec3 {
		var I = (this : Vec3);
		var nDotI = N.dot(I);
		var k = 1.0 - eta * eta * (1.0 - nDotI * nDotI);
		return (eta * I - (eta * nDotI + Math.sqrt(k)) * N) * (k < 0.0 ? 0.0 : 1.0); // if k < 0, result should be 0 vector
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
	private inline function arrayWrite(i:Int, v:Float)
		return switch i {
			case 0: this.x = v;
			case 1: this.y = v;
			case 2: this.z = v;
			default: null;
		}

	@:op(-a)
	static private inline function neg(a:Vec3)
		return new Vec3(-a.x, -a.y, -a.z);

	@:op(++a)
	static private inline function prefixIncrement(a:Vec3) {
		++a.x;
		++a.y;
		++a.z;
		return a.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(a:Vec3) {
		--a.x;
		--a.y;
		--a.z;
		return a.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(a:Vec3) {
		var ret = a.clone();
		++a.x;
		++a.y;
		++a.z;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(a:Vec3) {
		var ret = a.clone();
		--a.x;
		--a.y;
		--a.z;
		return ret;
	}

	@:op(a * b)
	static private inline function mul(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x * b.x, a.y * b.y, a.z * b.z);

	@:op(a * b) @:commutative
	static private inline function mulScalar(a:Vec3, b:Float):Vec3
		return new Vec3(a.x * b, a.y * b, a.z * b);

	@:op(a / b)
	static private inline function div(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x / b.x, a.y / b.y, a.z / b.z);

	@:op(a / b)
	static private inline function divScalar(a:Vec3, b:Float):Vec3
		return new Vec3(a.x / b, a.y / b, a.z / b);

	@:op(a / b)
	static private inline function divScalarInv(a:Float, b:Vec3):Vec3
		return new Vec3(a / b.x, a / b.y, a / b.z);

	@:op(a + b)
	static private inline function add(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x + b.x, a.y + b.y, a.z + b.z);

	@:op(a + b) @:commutative
	static private inline function addScalar(a:Vec3, b:Float):Vec3
		return new Vec3(a.x + b, a.y + b, a.z + b);

	@:op(a - b)
	static private inline function sub(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x - b.x, a.y - b.y, a.z - b.z);

	@:op(a - b)
	static private inline function subScalar(a:Vec3, b:Float):Vec3
		return new Vec3(a.x - b, a.y - b, a.z - b);

	@:op(b - a)
	static private inline function subScalarInv(a:Float, b:Vec3):Vec3
		return new Vec3(a - b.x, a - b.y, a - b.z);

	@:op(a == b)
	static private inline function equal(a:Vec3, b:Vec3):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z;

	@:op(a != b)
	static private inline function notEqual(a:Vec3, b:Vec3):Bool
		return !equal(a, b);
	#end // !macro

	// macros

	/**
	 * Copy from any object with .x .y .z fields
	 */
	@:overload(function(source:{x:Float, y:Float, z:Float}):Vec3 {})
	public macro function copyFrom(self:ExprOf<Vec3>, source:ExprOf<{x:Float, y:Float, z:Float}>):ExprOf<Vec3> {
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
	@:overload(function(target:{x:Float, y:Float, z:Float}):{x:Float, y:Float, z:Float} {})
	public macro function copyInto(self:ExprOf<Vec3>, target:ExprOf<{x:Float, y:Float, z:Float}>):ExprOf<{x:Float, y:Float, z:Float}> {
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
	public macro function copyIntoArray(self:ExprOf<Vec3>, array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>) {
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
	public macro function copyFromArray(self:ExprOf<Vec3>, array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>) {
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
	@:overload(function(source:{x:Float, y:Float, z:Float}):Vec3 {})
	public static macro function from(xyz:ExprOf<{x:Float, y:Float, z:Float}>):ExprOf<Vec3> {
		return macro {
			var source = $xyz;
			new Vec3(source.x, source.y, source.z);
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>):ExprOf<Vec3> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Vec3(array[0 + i], array[1 + i], array[2 + i]);
		}
	}
}
