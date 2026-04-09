package s.math;

/**
 * Interpolation function used for smoothing a normalized `Float` value.
 *
 * You can use predefined interpolation functions such as `Interpolation.Linear`
 * or provide a custom `Float->Float` function.
 *
 * These functions are typically used by animations, transitions, and UI effects
 * that evaluate progress in the `0.0..1.0` range and need a non-linear response.
 *
 * Example:
 * ```haxe
 * var t = Interpolation.InOutSine(0.35);
 * ```
 *
 * @see https://easings.net/
 */
abstract Interpolation(Float->Float) from Float->Float to Float->Float {
	@:op(a())
	inline function call(t:Float):Float
		return this(t);

	/** Identity interpolation with constant speed. */
	public static function Linear(t:Float)
		return t;

	/** Smooth cubic interpolation between `0` and `1`. */
	public static function Bezier(t:Float)
		return t * t * (3 - 2 * t);

	/** Quadratic ease-in interpolation. */
	public static function InQuad(t:Float)
		return t * t;

	/** Quadratic ease-out interpolation. */
	public static function OutQuad(t:Float)
		return (2 - t) * t;

	/** Quadratic ease-in-out interpolation. */
	public static function InOutQuad(t:Float)
		return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

	/** Quadratic ease-out-in interpolation. */
	public static function OutInQuad(t:Float)
		return t < 0.5 ? 0.5 * (2 - 2 * t) * (2 * t) : 0.5 * (1 - (2 - 2 * t) * (2 - 2 * t) + 1);

	/** Cubic ease-in interpolation. */
	public static function InCubic(t:Float)
		return t * t * t;

	/** Cubic ease-out interpolation. */
	public static function OutCubic(t:Float)
		return (t - 1) * (t - 1) * (t - 1) + 1;

	/** Cubic ease-in-out interpolation. */
	public static function InOutCubic(t:Float)
		return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

	/** Cubic ease-out-in interpolation. */
	public static function OutInCubic(t:Float)
		return t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);

	/** Quartic ease-in interpolation. */
	public static function InQuart(t:Float)
		return t * t * t * t;

	/** Quartic ease-out interpolation. */
	public static function OutQuart(t:Float)
		return 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1);

	/** Quartic ease-in-out interpolation. */
	public static function InOutQuart(t:Float)
		return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1);

	/** Quartic ease-out-in interpolation. */
	public static function OutInQuart(t:Float)
		return t < 0.5 ? 0.5 * (1 - (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * (1
			- (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 1);

	/** Quintic ease-in interpolation. */
	public static function InQuint(t:Float)
		return t * t * t * t * t;

	/** Quintic ease-out interpolation. */
	public static function OutQuint(t:Float)
		return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	/** Quintic ease-in-out interpolation. */
	public static function InOutQuint(t:Float)
		return t < 0.5 ? 16 * t * t * t * t * t : 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	/** Quintic ease-out-in interpolation. */
	public static function OutInQuint(t:Float)
		return t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1)
			+ 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);

	/** Sinusoidal ease-in interpolation. */
	public static function InSine(t:Float)
		return 1 - Math.cos(t * (Math.PI / 2));

	/** Sinusoidal ease-out interpolation. */
	public static function OutSine(t:Float)
		return Math.sin(t * (Math.PI / 2));

	/** Sinusoidal ease-in-out interpolation. */
	public static function InOutSine(t:Float)
		return -0.5 * (Math.cos(Math.PI * t) - 1);

	/** Sinusoidal ease-out-in interpolation. */
	public static function OutInSine(t:Float)
		return t < 0.5 ? 0.5 * (Math.sin(2 * t * Math.PI / 2)) : 0.5 * (-Math.cos(2 * (t - 0.5) * Math.PI / 2) + 2);

	/** Exponential ease-in interpolation. */
	public static function InExpo(t:Float)
		return Math.pow(2, 10 * (t - 1));

	/** Exponential ease-out interpolation. */
	public static function OutExpo(t:Float)
		return 1 - Math.pow(2, -10 * t);

	/** Exponential ease-in-out interpolation. */
	public static function InOutExpo(t:Float)
		return t < 0.5 ? 0.5 * Math.pow(2, (20 * t) - 10) : 0.5 * (2 - Math.pow(2, 10 - 20 * t));

	/** Exponential ease-out-in interpolation. */
	public static function OutInExpo(t:Float)
		return t < 0.5 ? 0.5 * (1 - Math.pow(2, -20 * t)) : 0.5 * (Math.pow(2, 20 * (t - 0.5)) + 1);

	/** Circular ease-in interpolation. */
	public static function InCirc(t:Float)
		return 1 - Math.sqrt(1 - t * t);

	/** Circular ease-out interpolation. */
	public static function OutCirc(t:Float)
		return Math.sqrt(1 - (t - 1) * (t - 1));

	/** Circular ease-in-out interpolation. */
	public static function InOutCirc(t:Float)
		return t < 0.5 ? 0.5 * (1 - Math.sqrt(1 - 4 * t * t)) : 0.5 * (Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 1);

	/** Circular ease-out-in interpolation. */
	public static function OutInCirc(t:Float)
		return t < 0.5 ? 0.5 * Math.sqrt(1 - 4 * (t - 0.5) * (t - 0.5)) : 0.5 * (-Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 2);

	/** Elastic ease-in interpolation. */
	public static function InElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * (2 * Math.PI) / 4.5));

	/** Elastic ease-out interpolation. */
	public static function OutElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI) / 4.5) + 1);

	/** Elastic ease-in-out interpolation. */
	public static function InOutElastic(t:Float)
		return t == 0 ? 0 : (t == 1 ? 1 : t < 0.5 ?
			-Math.pow(2,
				20 * t - 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5) / 2 : (Math.pow(2,
				-20 * t + 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5)) / 2
				+ 1);

	/** Elastic ease-out-in interpolation. */
	public static function OutInElastic(t:Float)
		return t < 0.5 ? 0.5 * (Math.pow(2, -20 * t) * Math.sin((20 * t - 1.125) * (2 * Math.PI) / 4.5)
			+ 1) : 0.5 * (-Math.pow(2, 20 * (t - 0.5) - 10) * Math.sin((20 * (t - 0.5) - 1.125) * (2 * Math.PI) / 4.5) + 2);

	/** Backtracking ease-in interpolation. */
	public static function InBack(t:Float)
		return 2.70158 * t * t * t - 1.70158 * t * t;

	/** Backtracking ease-out interpolation. */
	public static function OutBack(t:Float)
		return 1 + 2.70158 * Math.pow(t - 1, 3) + 1.70158 * Math.pow(t - 1, 2);

	/** Backtracking ease-in-out interpolation. */
	public static function InOutBack(t:Float)
		return t < 0.5 ? (2 * t * 2 * t * ((2.5949095 + 1) * 2 * t - 2.5949095)) / 2 : (Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095)
			+ 2) / 2;

	/** Backtracking ease-out-in interpolation. */
	public static function OutInBack(t:Float)
		return t < 0.5 ? 0.5 * (Math.pow(2 * t - 1, 2) * ((2.5949095 + 1) * (t * 2 - 1) + 2.5949095)
			+ 1) : 0.5 * (1 + Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095) + 1);

	/** Bounce ease-in interpolation. */
	public static function InBounce(t:Float)
		return 1 - Interpolation.OutBounce(1 - t);

	/** Bounce ease-out interpolation. */
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

	/** Bounce ease-in-out interpolation. */
	public static function InOutBounce(t:Float)
		return t < 0.5 ? (1 - Interpolation.OutBounce(1 - 2 * t)) / 2 : (1 + Interpolation.OutBounce(2 * t - 1)) / 2;

	/** Bounce ease-out-in interpolation. */
	public static function OutInBounce(t:Float)
		return t < 0.5 ? 0.5 * Interpolation.OutBounce(2 * t) : 0.5 * (1 - Interpolation.OutBounce(2 - 2 * t) + 1);

	/** Step interpolation with a threshold at `0.5`. */
	public static function Step(t:Float)
		return s.math.SMath.step(0.5, t);

	/** Smoothstep interpolation in the `0.0..1.0` range. */
	public static function Smoothstep(t:Float)
		return s.math.SMath.smoothstep(0.0, 1.0, t);
}
