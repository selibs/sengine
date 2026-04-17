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
enum abstract Interpolation(Float->Float) from Float->Float to Float->Float {
	@:op(a())
	inline function call(t:Float):Float
		return this(t);

	/** Step interpolation with a threshold at `0.5`. */
	public static final Step:Interpolation = (t:Float) -> s.math.SMath.step(0.5, t);

	/** Smoothstep interpolation in the `0.0..1.0` range. */
	public static final Smoothstep:Interpolation = (t:Float) -> s.math.SMath.smoothstep(0.0, 1.0, t);

	/** Identity interpolation with constant speed. */
	public static final Linear:Interpolation = (t:Float) -> t;

	/** Smooth cubic interpolation between `0` and `1`. */
	public static final Bezier:Interpolation = (t:Float) -> t * t * (3 - 2 * t);

	/** Quadratic ease-in interpolation. */
	public static final InQuad:Interpolation = (t:Float) -> t * t;

	/** Quadratic ease-out interpolation. */
	public static final OutQuad:Interpolation = (t:Float) -> (2 - t) * t;

	/** Quadratic ease-in-out interpolation. */
	public static final InOutQuad:Interpolation = (t:Float) -> t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

	/** Quadratic ease-out-in interpolation. */
	public static final OutInQuad:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (2 - 2 * t) * (2 * t) : 0.5 * (1 - (2 - 2 * t) * (2 - 2 * t) + 1);

	/** Cubic ease-in interpolation. */
	public static final InCubic:Interpolation = (t:Float) -> t * t * t;

	/** Cubic ease-out interpolation. */
	public static final OutCubic:Interpolation = (t:Float) -> (t - 1) * (t - 1) * (t - 1) + 1;

	/** Cubic ease-in-out interpolation. */
	public static final InOutCubic:Interpolation = (t:Float) -> t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

	/** Cubic ease-out-in interpolation. */
	public static final OutInCubic:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) +
		1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t
		- 2)
		+ 2);

	/** Quartic ease-in interpolation. */
	public static final InQuart:Interpolation = (t:Float) -> t * t * t * t;

	/** Quartic ease-out interpolation. */
	public static final OutQuart:Interpolation = (t:Float) -> 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1);

	/** Quartic ease-in-out interpolation. */
	public static final InOutQuart:Interpolation = (t:Float) -> t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1);

	/** Quartic ease-out-in interpolation. */
	public static final OutInQuart:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (1 - (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * (1
		- (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 1);

	/** Quintic ease-in interpolation. */
	public static final InQuint:Interpolation = (t:Float) -> t * t * t * t * t;

	/** Quintic ease-out interpolation. */
	public static final OutQuint:Interpolation = (t:Float) -> (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	/** Quintic ease-in-out interpolation. */
	public static final InOutQuint:Interpolation = (t:Float) -> t < 0.5 ? 16 * t * t * t * t * t : 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;

	/** Quintic ease-out-in interpolation. */
	public static final OutInQuint:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1)
		+ 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);

	/** Sinusoidal ease-in interpolation. */
	public static final InSine:Interpolation = (t:Float) -> 1 - Math.cos(t * (Math.PI / 2));

	/** Sinusoidal ease-out interpolation. */
	public static final OutSine:Interpolation = (t:Float) -> Math.sin(t * (Math.PI / 2));

	/** Sinusoidal ease-in-out interpolation. */
	public static final InOutSine:Interpolation = (t:Float) -> -0.5 * (Math.cos(Math.PI * t) - 1);

	/** Sinusoidal ease-out-in interpolation. */
	public static final OutInSine:Interpolation = (t:Float) ->
		t < 0.5 ? 0.5 * (Math.sin(2 * t * Math.PI / 2)) : 0.5 * (-Math.cos(2 * (t - 0.5) * Math.PI / 2) + 2);

	/** Exponential ease-in interpolation. */
	public static final InExpo:Interpolation = (t:Float) -> Math.pow(2, 10 * (t - 1));

	/** Exponential ease-out interpolation. */
	public static final OutExpo:Interpolation = (t:Float) -> 1 - Math.pow(2, -10 * t);

	/** Exponential ease-in-out interpolation. */
	public static final InOutExpo:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * Math.pow(2, (20 * t) - 10) : 0.5 * (2 - Math.pow(2, 10 - 20 * t));

	/** Exponential ease-out-in interpolation. */
	public static final OutInExpo:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (1 - Math.pow(2, -20 * t)) : 0.5 * (Math.pow(2, 20 * (t - 0.5)) + 1);

	/** Circular ease-in interpolation. */
	public static final InCirc:Interpolation = (t:Float) -> 1 - Math.sqrt(1 - t * t);

	/** Circular ease-out interpolation. */
	public static final OutCirc:Interpolation = (t:Float) -> Math.sqrt(1 - (t - 1) * (t - 1));

	/** Circular ease-in-out interpolation. */
	public static final InOutCirc:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (1 - Math.sqrt(1 - 4 * t * t)) : 0.5 * (Math.sqrt(1 - 4 * (t - 1) * (t - 1)) +
		1);

	/** Circular ease-out-in interpolation. */
	public static final OutInCirc:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * Math.sqrt(1 - 4 * (t - 0.5) * (t - 0.5)) : 0.5 * (-Math.sqrt(1
		- 4 * (t - 1) * (t - 1)) + 2);

	/** Elastic ease-in interpolation. */
	public static final InElastic:Interpolation = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 :
		-Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * (2 * Math.PI) / 4.5));

	/** Elastic ease-out interpolation. */
	public static final OutElastic:Interpolation = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 : Math.pow(2,
		-10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI) / 4.5)
		+ 1);

	/** Elastic ease-in-out interpolation. */
	public static final InOutElastic:Interpolation = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 : t < 0.5 ?
		-Math.pow(2,
			20 * t - 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5) / 2 : (Math.pow(2,
			-20 * t + 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5)) / 2
			+ 1);

	/** Elastic ease-out-in interpolation. */
	public static final OutInElastic:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (Math.pow(2, -20 * t) * Math.sin((20 * t - 1.125) * (2 * Math.PI) / 4.5)
		+ 1) : 0.5 * (-Math.pow(2, 20 * (t - 0.5) - 10) * Math.sin((20 * (t - 0.5) - 1.125) * (2 * Math.PI) / 4.5) + 2);

	/** Backtracking ease-in interpolation. */
	public static final InBack:Interpolation = (t:Float) -> 2.70158 * t * t * t - 1.70158 * t * t;

	/** Backtracking ease-out interpolation. */
	public static final OutBack:Interpolation = (t:Float) -> 1 + 2.70158 * Math.pow(t - 1, 3) + 1.70158 * Math.pow(t - 1, 2);

	/** Backtracking ease-in-out interpolation. */
	public static final InOutBack:Interpolation = (t:Float) -> t < 0.5 ? (2 * t * 2 * t * ((2.5949095 + 1) * 2 * t - 2.5949095)) / 2 : (Math.pow(2 * t - 2,
		2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095)
		+ 2) / 2;

	/** Backtracking ease-out-in interpolation. */
	public static final OutInBack:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * (Math.pow(2 * t - 1, 2) * ((2.5949095 + 1) * (t * 2 - 1) + 2.5949095)
		+ 1) : 0.5 * (1 + Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095) + 1);

	/** Bounce ease-in interpolation. */
	public static final InBounce:Interpolation = (t:Float) -> 1 - Interpolation.OutBounce(1 - t);

	/** Bounce ease-out interpolation. */
	public static final OutBounce:Interpolation = (t:Float) -> {
		if (t < 1 / 2.75)
			7.5625 * t * t;
		else if (t < 2 / 2.75)
			7.5625 * (t - 0.545455) * (t - 0.545455) + 0.75;
		else if (t < 2.5 / 2.75)
			7.5625 * (t - 0.818182) * (t - 0.818182) + 0.9375;
		else
			7.5625 * (t - 0.954545) * (t - 0.954545) + 0.984375;
	}

	/** Bounce ease-in-out interpolation. */
	public static final InOutBounce:Interpolation = (t:Float) -> t < 0.5 ? (1 - Interpolation.OutBounce(1 - 2 * t)) / 2 : (1
		+ Interpolation.OutBounce(2 * t - 1)) / 2;

	/** Bounce ease-out-in interpolation. */
	public static final OutInBounce:Interpolation = (t:Float) -> t < 0.5 ? 0.5 * Interpolation.OutBounce(2 * t) : 0.5 * (1
		- Interpolation.OutBounce(2 - 2 * t) + 1);
}
