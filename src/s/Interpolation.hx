package s;

/**
	This abstract class defines interpolation functions used for smoothing normalized `Float` value.

	You can use predefined interpolation functions such as `Interpolation.Linear` or define custom functions.
 */
abstract Interpolation(Float->Float) from Float->Float to Float->Float {
	@:op(a())
	inline function call(t:Float):Float
		return this(t);

	public static function Linear(t:Float)
		return t;

	public static function Bezier(t:Float)
		return t * t * (3 - 2 * t);

	// quad
	public static function InQuad(t:Float)
		return t * t;

	public static function OutQuad(t:Float)
		return (2 - t) * t;

	public static function InOutQuad(t:Float)
		return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

	public static function OutInQuad(t:Float)
		return t < 0.5 ? 0.5 * (2 - 2 * t) * (2 * t) : 0.5 * (1 - (2 - 2 * t) * (2 - 2 * t) + 1);

	// cubic
	public static function InCubic(t:Float)
		return t * t * t;

	public static function OutCubic(t:Float)
		return (t - 1) * (t - 1) * (t - 1) + 1;

	public static function InOutCubic(t:Float)
		return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

	public static function OutInCubic(t:Float)
		return t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);

	// quart
	public static function InQuart(t:Float)
		return t * t * t * t;

	public static function OutQuart(t:Float)
		return 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1);

	public static function InOutQuart(t:Float)
		return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1);

	public static function OutInQuart(t:Float)
		return t < 0.5 ? 0.5 * (1 - (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * (1
			- (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 1);

	// quint
	public static function InQuint(t:Float)
		return t * t * t * t * t;

	public static function OutQuint(t:Float)
		return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	public static function InOutQuint(t:Float)
		return t < 0.5 ? 16 * t * t * t * t * t : 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	public static function OutInQuint(t:Float)
		return t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1)
			+ 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);

	// sine
	public static function InSine(t:Float)
		return 1 - Math.cos(t * (Math.PI / 2));

	public static function OutSine(t:Float)
		return Math.sin(t * (Math.PI / 2));

	public static function InOutSine(t:Float)
		return -0.5 * (Math.cos(Math.PI * t) - 1);

	public static function OutInSine(t:Float)
		return t < 0.5 ? 0.5 * (Math.sin(2 * t * Math.PI / 2)) : 0.5 * (-Math.cos(2 * (t - 0.5) * Math.PI / 2) + 2);

	// expo
	public static function InExpo(t:Float)
		return Math.pow(2, 10 * (t - 1));

	public static function OutExpo(t:Float)
		return 1 - Math.pow(2, -10 * t);

	public static function InOutExpo(t:Float)
		return t < 0.5 ? 0.5 * Math.pow(2, (20 * t) - 10) : 0.5 * (2 - Math.pow(2, 10 - 20 * t));

	public static function OutInExpo(t:Float)
		return t < 0.5 ? 0.5 * (1 - Math.pow(2, -20 * t)) : 0.5 * (Math.pow(2, 20 * (t - 0.5)) + 1);

	// circ
	public static function InCirc(t:Float)
		return 1 - Math.sqrt(1 - t * t);

	public static function OutCirc(t:Float)
		return Math.sqrt(1 - (t - 1) * (t - 1));

	public static function InOutCirc(t:Float)
		return t < 0.5 ? 0.5 * (1 - Math.sqrt(1 - 4 * t * t)) : 0.5 * (Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 1);

	public static function OutInCirc(t:Float)
		return t < 0.5 ? 0.5 * Math.sqrt(1 - 4 * (t - 0.5) * (t - 0.5)) : 0.5 * (-Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 2);

	// elastic
	public static function InElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * (2 * Math.PI) / 4.5));

	public static function OutElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI) / 4.5) + 1);

	public static function InOutElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : t < 0.5 ?
			-Math.pow(2,
				20 * t - 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5) / 2 : (Math.pow(2,
				-20 * t + 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5)) / 2
				+ 1);

	public static function OutInElastic(t:Float)
		return t < 0.5 ? 0.5 * (Math.pow(2, -20 * t) * Math.sin((20 * t - 1.125) * (2 * Math.PI) / 4.5)
			+ 1) : 0.5 * (-Math.pow(2, 20 * (t - 0.5) - 10) * Math.sin((20 * (t - 0.5) - 1.125) * (2 * Math.PI) / 4.5) + 2);

	// back
	public static function InBack(t:Float)
		return 2.70158 * t * t * t - 1.70158 * t * t;

	public static function OutBack(t:Float)
		return 1 + 2.70158 * Math.pow(t - 1, 3) + 1.70158 * Math.pow(t - 1, 2);

	public static function InOutBack(t:Float)
		return t < 0.5 ? (2 * t * 2 * t * ((2.5949095 + 1) * 2 * t - 2.5949095)) / 2 : (Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095)
			+ 2) / 2;

	public static function OutInBack(t:Float)
		return t < 0.5 ? 0.5 * (Math.pow(2 * t - 1, 2) * ((2.5949095 + 1) * (t * 2 - 1) + 2.5949095)
			+ 1) : 0.5 * (1 + Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095) + 1);

	// bounce
	public static function InBounce(t:Float)
		return 1 - Interpolation.OutBounce(1 - t);

	public static function OutBounce(t:Float)
		return {
			if (t < 1 / 2.75)
				return 7.5625 * t * t;
			else if (t < 2 / 2.75)
				return 7.5625 * (t - 0.545455) * (t - 0.545455) + 0.75;
			else if (t < 2.5 / 2.75)
				return 7.5625 * (t - 0.818182) * (t - 0.818182) + 0.9375;
			else
				return 7.5625 * (t - 0.954545) * (t - 0.954545) + 0.984375;
		}

	public static function InOutBounce(t:Float)
		return t < 0.5 ? (1 - Interpolation.OutBounce(1 - 2 * t)) / 2 : (1 + Interpolation.OutBounce(2 * t - 1)) / 2;

	public static function OutInBounce(t:Float)
		return t < 0.5 ? 0.5 * Interpolation.OutBounce(2 * t) : 0.5 * (1 - Interpolation.OutBounce(2 - 2 * t) + 1);

	// special
	public static function Step(t:Float)
		return s.math.SMath.step(0.5, t);

	public static function Smoothstep(t:Float)
		return s.math.SMath.smoothstep(0.0, 1.0, t);
}
