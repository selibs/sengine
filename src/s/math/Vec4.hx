package s.math;

#if macro
import haxe.macro.Expr.ExprOf;
#end
import kha.math.FastVector4 as KhaVec4;

@:nullSafety
@:forward.new
@:forward(x, y, z, w) #if !macro @:build(s.math.SMath.Swizzle.generateFields(4)) #end
extern abstract Vec4(KhaVec4) from KhaVec4 to KhaVec4 {
	#if !macro
	@:to
	public inline function toVec4I():Vec4I {
		return Vec4I.fromVec4(this);
	}

	public inline function set(x:Float, y:Float, z:Float, w:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public inline function clone() {
		return new Vec4(this.x, this.y, this.z, this.w);
	}

	// Trigonometric
	public inline function radians():Vec4 {
		return (this : Vec4) * Math.PI / 180;
	}

	public inline function degrees():Vec4 {
		return (this : Vec4) * 180 / Math.PI;
	}

	public inline function sin():Vec4 {
		return new Vec4(Math.sin(this.x), Math.sin(this.y), Math.sin(this.z), Math.sin(this.w));
	}

	public inline function cos():Vec4 {
		return new Vec4(Math.cos(this.x), Math.cos(this.y), Math.cos(this.z), Math.cos(this.w));
	}

	public inline function tan():Vec4 {
		return new Vec4(Math.tan(this.x), Math.tan(this.y), Math.tan(this.z), Math.tan(this.w));
	}

	public inline function asin():Vec4 {
		return new Vec4(Math.asin(this.x), Math.asin(this.y), Math.asin(this.z), Math.asin(this.w));
	}

	public inline function acos():Vec4 {
		return new Vec4(Math.acos(this.x), Math.acos(this.y), Math.acos(this.z), Math.acos(this.w));
	}

	public inline function atan():Vec4 {
		return new Vec4(Math.atan(this.x), Math.atan(this.y), Math.atan(this.z), Math.atan(this.w));
	}

	public inline function atan2(b:Vec4):Vec4 {
		return new Vec4(Math.atan2(this.x, b.x), Math.atan2(this.y, b.y), Math.atan2(this.z, b.z), Math.atan2(this.w, b.w));
	}

	// Exponential
	public inline function pow(e:Vec4):Vec4 {
		return new Vec4(Math.pow(this.x, e.x), Math.pow(this.y, e.y), Math.pow(this.z, e.z), Math.pow(this.w, e.w));
	}

	public inline function exp():Vec4 {
		return new Vec4(Math.exp(this.x), Math.exp(this.y), Math.exp(this.z), Math.exp(this.w));
	}

	public inline function log():Vec4 {
		return new Vec4(Math.log(this.x), Math.log(this.y), Math.log(this.z), Math.log(this.w));
	}

	public inline function exp2():Vec4 {
		return new Vec4(Math.pow(2, this.x), Math.pow(2, this.y), Math.pow(2, this.z), Math.pow(2, this.w));
	}

	public inline function log2():Vec4 @:privateAccess {
		return new Vec4(SMath.log2f(this.x), SMath.log2f(this.y), SMath.log2f(this.z), SMath.log2f(this.w));
	}

	public inline function sqrt():Vec4 {
		return new Vec4(Math.sqrt(this.x), Math.sqrt(this.y), Math.sqrt(this.z), Math.sqrt(this.w));
	}

	public inline function inverseSqrt():Vec4 {
		return 1.0 / sqrt();
	}

	// Common
	public inline function abs():Vec4 {
		return new Vec4(Math.abs(this.x), Math.abs(this.y), Math.abs(this.z), Math.abs(this.w));
	}

	public inline function sign():Vec4 {
		return new Vec4(this.x > 0.?1.:(this.x < 0.? -1.:0.), this.y > 0.?1.:(this.y < 0.? -1.:0.), this.z > 0.?1.:(this.z < 0.?
			-1.:0.), this.w > 0.?1.:(this.w < 0.? -1.:0.));
	}

	public inline function floor():Vec4 {
		return new Vec4(Math.floor(this.x), Math.floor(this.y), Math.floor(this.z), Math.floor(this.w));
	}

	public inline function ceil():Vec4 {
		return new Vec4(Math.ceil(this.x), Math.ceil(this.y), Math.ceil(this.z), Math.ceil(this.w));
	}

	public inline function fract():Vec4 {
		return (this : Vec4) - floor();
	}

	extern overload public inline function mod(d:Float):Vec4 {
		return (this : Vec4) - d * ((this : Vec4) / d).floor();
	}

	extern overload public inline function mod(d:Vec4):Vec4 {
		return (this : Vec4) - d * ((this : Vec4) / d).floor();
	}

	extern overload public inline function min(b:Vec4):Vec4 {
		return new Vec4(b.x < this.x ? b.x : this.x, b.y < this.y ? b.y : this.y, b.z < this.z ? b.z : this.z, b.w < this.w ? b.w : this.w);
	}

	extern overload public inline function min(b:Float):Vec4 {
		return new Vec4(b < this.x ? b : this.x, b < this.y ? b : this.y, b < this.z ? b : this.z, b < this.w ? b : this.w);
	}

	extern overload public inline function max(b:Vec4):Vec4 {
		return new Vec4(this.x < b.x ? b.x : this.x, this.y < b.y ? b.y : this.y, this.z < b.z ? b.z : this.z, this.w < b.w ? b.w : this.w);
	}

	extern overload public inline function max(b:Float):Vec4 {
		return new Vec4(this.x < b ? b : this.x, this.y < b ? b : this.y, this.z < b ? b : this.z, this.w < b ? b : this.w);
	}

	extern overload public inline function clamp(minLimit:Vec4, maxLimit:Vec4) {
		return max(minLimit).min(maxLimit);
	}

	extern overload public inline function clamp(minLimit:Float, maxLimit:Float) {
		return max(minLimit).min(maxLimit);
	}

	extern overload public inline function mix(b:Vec4, t:Vec4):Vec4 {
		return (this : Vec4) * (1.0 - t) + b * t;
	}

	extern overload public inline function mix(b:Vec4, t:Float):Vec4 {
		return (this : Vec4) * (1.0 - t) + b * t;
	}

	extern overload public inline function step(edge:Vec4):Vec4 {
		return new Vec4(this.x < edge.x ? 0.0 : 1.0, this.y < edge.y ? 0.0 : 1.0, this.z < edge.z ? 0.0 : 1.0, this.w < edge.w ? 0.0 : 1.0);
	}

	extern overload public inline function step(edge:Float):Vec4 {
		return new Vec4(this.x < edge ? 0.0 : 1.0, this.y < edge ? 0.0 : 1.0, this.z < edge ? 0.0 : 1.0, this.w < edge ? 0.0 : 1.0);
	}

	extern overload public inline function smoothstep(edge0:Vec4, edge1:Vec4):Vec4 {
		var t = (((this : Vec4) - edge0) / (edge1 - edge0)).clamp(0, 1);
		return t * t * (3.0 - 2.0 * t);
	}

	extern overload public inline function smoothstep(edge0:Float, edge1:Float):Vec4 {
		var t = (((this : Vec4) - edge0) / (edge1 - edge0)).clamp(0, 1);
		return t * t * (3.0 - 2.0 * t);
	}

	// Geometric
	public inline function length():Float {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
	}

	public inline function distance(b:Vec4):Float {
		return (b - this).length();
	}

	public inline function dot(b:Vec4):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z + this.w * b.w;
	}

	public inline function normalize():Vec4 {
		var v:Vec4 = this;
		var lenSq = v.dot(this);
		var denominator = lenSq == 0.0 ? 1.0 : Math.sqrt(lenSq); // for 0 length, return zero vector rather than infinity
		return v / denominator;
	}

	public inline function faceforward(I:Vec4, Nref:Vec4):Vec4 {
		return new Vec4(this.x, this.y, this.z, this.w) * (Nref.dot(I) < 0 ? 1 : -1);
	}

	public inline function reflect(N:Vec4):Vec4 {
		var I = (this : Vec4);
		return I - 2 * N.dot(I) * N;
	}

	public inline function refract(N:Vec4, eta:Float):Vec4 {
		var I = (this : Vec4);
		var nDotI = N.dot(I);
		var k = 1.0 - eta * eta * (1.0 - nDotI * nDotI);
		return (eta * I - (eta * nDotI + Math.sqrt(k)) * N) * (k < 0.0 ? 0.0 : 1.0); // if k < 0, result should be 0 vector
	}

	public inline function toString() {
		return 'vec4(${this.x}, ${this.y}, ${this.z}, ${this.w})';
	}

	@:op([])
	private inline function arrayRead(i:Int)
		return switch i {
			case 0: this.x;
			case 1: this.y;
			case 2: this.z;
			case 3: this.w;
			default: null;
		}

	@:op([])
	private inline function arrayWrite(i:Int, v:Float)
		return switch i {
			case 0: this.x = v;
			case 1: this.y = v;
			case 2: this.z = v;
			case 3: this.w = v;
			default: null;
		}

	@:op(-a)
	static private inline function neg(a:Vec4)
		return new Vec4(-a.x, -a.y, -a.z, -a.w);

	@:op(++a)
	static private inline function prefixIncrement(a:Vec4) {
		++a.x;
		++a.y;
		++a.z;
		++a.w;
		return a.clone();
	}

	@:op(--a)
	static private inline function prefixDecrement(a:Vec4) {
		--a.x;
		--a.y;
		--a.z;
		--a.w;
		return a.clone();
	}

	@:op(a++)
	static private inline function postfixIncrement(a:Vec4) {
		var ret = a.clone();
		++a.x;
		++a.y;
		++a.z;
		++a.w;
		return ret;
	}

	@:op(a--)
	static private inline function postfixDecrement(a:Vec4) {
		var ret = a.clone();
		--a.x;
		--a.y;
		--a.z;
		--a.w;
		return ret;
	}

	@:op(a * b)
	static private inline function mul(a:Vec4, b:Vec4):Vec4
		return new Vec4(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w);

	@:op(a * b) @:commutative
	static private inline function mulScalar(a:Vec4, b:Float):Vec4
		return new Vec4(a.x * b, a.y * b, a.z * b, a.w * b);

	@:op(a / b)
	static private inline function div(a:Vec4, b:Vec4):Vec4
		return new Vec4(a.x / b.x, a.y / b.y, a.z / b.z, a.w / b.w);

	@:op(a / b)
	static private inline function divScalar(a:Vec4, b:Float):Vec4
		return new Vec4(a.x / b, a.y / b, a.z / b, a.w / b);

	@:op(a / b)
	static private inline function divScalarInv(a:Float, b:Vec4):Vec4
		return new Vec4(a / b.x, a / b.y, a / b.z, a / b.w);

	@:op(a + b)
	static private inline function add(a:Vec4, b:Vec4):Vec4
		return new Vec4(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w);

	@:op(a + b) @:commutative
	static private inline function addScalar(a:Vec4, b:Float):Vec4
		return new Vec4(a.x + b, a.y + b, a.z + b, a.w + b);

	@:op(a - b)
	static private inline function sub(a:Vec4, b:Vec4):Vec4
		return new Vec4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w);

	@:op(a - b)
	static private inline function subScalar(a:Vec4, b:Float):Vec4
		return new Vec4(a.x - b, a.y - b, a.z - b, a.w - b);

	@:op(b - a)
	static private inline function subScalarInv(a:Float, b:Vec4):Vec4
		return new Vec4(a - b.x, a - b.y, a - b.z, a - b.w);

	@:op(a == b)
	static private inline function equal(a:Vec4, b:Vec4):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;

	@:op(a != b)
	static private inline function notEqual(a:Vec4, b:Vec4):Bool
		return !equal(a, b);
	#end // !macro

	// macros

	/**
	 * Copy from any object with .x .y .z .w fields
	 */
	@:overload(function(source:{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	}):Vec4 {})
	public macro function copyFrom(self:ExprOf<Vec4>, source:ExprOf<{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	}>):ExprOf<Vec4> {
		return macro {
			var self = $self;
			var source = $source;
			self.x = source.x;
			self.y = source.y;
			self.z = source.z;
			self.w = source.w;
			self;
		}
	}

	/**
	 * Copy into any object with .x .y .z .w fields
	 */
	@:overload(function(target:{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	}):{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	} {})
	public macro function copyInto(self:ExprOf<Vec4>, target:ExprOf<{x:Float, y:Float, z:Float}>):ExprOf<{x:Float, y:Float, z:Float}> {
		return macro {
			var self = $self;
			var target = $target;
			target.x = self.x;
			target.y = self.y;
			target.z = self.z;
			target.w = self.w;
			target;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyIntoArray(self:ExprOf<Vec4>, array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			array[0 + i] = self.x;
			array[1 + i] = self.y;
			array[2 + i] = self.z;
			array[3 + i] = self.w;
			array;
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public macro function copyFromArray(self:ExprOf<Vec4>, array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>) {
		return macro {
			var self = $self;
			var array = $array;
			var i:Int = $index;
			self.x = array[0 + i];
			self.y = array[1 + i];
			self.z = array[2 + i];
			self.w = array[3 + i];
			self;
		}
	}

	// static macros

	/**
	 * Create from any object with .x .y .z .w fields
	 */
	@:overload(function(source:{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	}):Vec4 {})
	public static macro function from(xyzw:ExprOf<{
		x:Float,
		y:Float,
		z:Float,
		w:Float
	}>):ExprOf<Vec4> {
		return macro {
			var source = $xyzw;
			new Vec4(source.x, source.y, source.z, source.w);
		}
	}

	@:overload(function<T>(arrayLike:T, index:Int):T {})
	public static macro function fromArray(array:ExprOf<ArrayAccess<Float>>, index:ExprOf<Int>):ExprOf<Vec4> {
		return macro {
			var array = $array;
			var i:Int = $index;
			new Vec4(array[0 + i], array[1 + i], array[2 + i], array[3 + i]);
		}
	}
}
