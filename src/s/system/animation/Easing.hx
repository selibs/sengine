package s.system.animation;

/**
	This abstract class defines easing functions used for smooth animations.

	Easing functions determine how animation progress is interpolated over time.
	They can create effects such as acceleration, deceleration, and bouncing.

	You can use predefined easing functions such as `Easing.Linear` or define custom functions.
 */
abstract Easing((Float) -> Float) from (Float) -> Float to (Float) -> Float {
	public static var Linear = (t:Float) -> t;
	public static var Bezier = (t:Float) -> t * t * (3 - 2 * t);
	// quad
	public static var InQuad = (t:Float) -> t * t;
	public static var OutQuad = (t:Float) -> (2 - t) * t;
	public static var InOutQuad = (t:Float) -> t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
	public static var OutInQuad = (t:Float) -> t < 0.5 ? 0.5 * (2 - 2 * t) * (2 * t) : 0.5 * (1 - (2 - 2 * t) * (2 - 2 * t) + 1);
	// cubic
	public static var InCubic = (t:Float) -> t * t * t;
	public static var OutCubic = (t:Float) -> (t - 1) * (t - 1) * (t - 1) + 1;
	public static var InOutCubic = (t:Float) -> t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
	public static var OutInCubic = (t:Float) -> t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2)
		+ 2);
	// quart
	public static var InQuart = (t:Float) -> t * t * t * t;
	public static var OutQuart = (t:Float) -> 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1);
	public static var InOutQuart = (t:Float) -> t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1);
	public static var OutInQuart = (t:Float) -> t < 0.5 ? 0.5 * (1 - (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) + 1) : 0.5 * (1
		- (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 1);
	// quint
	public static var InQuint = (t:Float) -> t * t * t * t * t;
	public static var OutQuint = (t:Float) -> (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;
	public static var InOutQuint = (t:Float) -> t < 0.5 ? 16 * t * t * t * t * t : 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;
	public static var OutInQuint = (t:Float) -> t < 0.5 ? 0.5 * ((2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1) * (2 * t - 1)
		+ 1) : 0.5 * ((2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) * (2 * t - 2) + 2);
	// sine
	public static var InSine = (t:Float) -> 1 - Math.cos(t * (Math.PI / 2));
	public static var OutSine = (t:Float) -> Math.sin(t * (Math.PI / 2));
	public static var InOutSine = (t:Float) -> -0.5 * (Math.cos(Math.PI * t) - 1);
	public static var OutInSine = (t:Float) -> t < 0.5 ? 0.5 * (Math.sin(2 * t * Math.PI / 2)) : 0.5 * (-Math.cos(2 * (t - 0.5) * Math.PI / 2) + 2);
	// expo
	public static var InExpo = (t:Float) -> Math.pow(2, 10 * (t - 1));
	public static var OutExpo = (t:Float) -> 1 - Math.pow(2, -10 * t);
	public static var InOutExpo = (t:Float) -> t < 0.5 ? 0.5 * Math.pow(2, (20 * t) - 10) : 0.5 * (2 - Math.pow(2, 10 - 20 * t));
	public static var OutInExpo = (t:Float) -> t < 0.5 ? 0.5 * (1 - Math.pow(2, -20 * t)) : 0.5 * (Math.pow(2, 20 * (t - 0.5)) + 1);
	// circ
	public static var InCirc = (t:Float) -> 1 - Math.sqrt(1 - t * t);
	public static var OutCirc = (t:Float) -> Math.sqrt(1 - (t - 1) * (t - 1));
	public static var InOutCirc = (t:Float) -> t < 0.5 ? 0.5 * (1 - Math.sqrt(1 - 4 * t * t)) : 0.5 * (Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 1);
	public static var OutInCirc = (t:Float) -> t < 0.5 ? 0.5 * Math.sqrt(1 - 4 * (t - 0.5) * (t - 0.5)) : 0.5 * (-Math.sqrt(1 - 4 * (t - 1) * (t - 1)) + 2);
	// elastic
	public static var InElastic = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 : -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * (2 * Math.PI) / 4.5));
	public static var OutElastic = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI) / 4.5) + 1);
	public static var InOutElastic = (t:Float) -> t == 0 ? 0 : (t == 1 ? 1 : t < 0.5 ?
		-Math.pow(2,
			20 * t - 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5) / 2 : (Math.pow(2,
			-20 * t + 10) * Math.sin((20 * t - 11.125) * (2 * Math.PI) / 4.5)) / 2
			+ 1);
	public static var OutInElastic = (t:Float) -> t < 0.5 ? 0.5 * (Math.pow(2, -20 * t) * Math.sin((20 * t - 1.125) * (2 * Math.PI) / 4.5)
		+ 1) : 0.5 * (-Math.pow(2, 20 * (t - 0.5) - 10) * Math.sin((20 * (t - 0.5) - 1.125) * (2 * Math.PI) / 4.5) + 2);
	// back
	public static var InBack = (t:Float) -> 2.70158 * t * t * t - 1.70158 * t * t;
	public static var OutBack = (t:Float) -> 1 + 2.70158 * Math.pow(t - 1, 3) + 1.70158 * Math.pow(t - 1, 2);
	public static var InOutBack = (t:Float) -> t < 0.5 ? (2 * t * 2 * t * ((2.5949095 + 1) * 2 * t - 2.5949095)) / 2 : (Math.pow(2 * t - 2,
		2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095)
		+ 2) / 2;
	public static var OutInBack = (t:Float) -> t < 0.5 ? 0.5 * (Math.pow(2 * t - 1, 2) * ((2.5949095 + 1) * (t * 2 - 1) + 2.5949095)
		+ 1) : 0.5 * (1 + Math.pow(2 * t - 2, 2) * ((2.5949095 + 1) * (t * 2 - 2) + 2.5949095) + 1);
	// bounce
	public static var InBounce = (t:Float) -> 1 - Easing.OutBounce(1 - t);
	public static var OutBounce = (t:Float) -> {
		if (t < 1 / 2.75)
			return 7.5625 * t * t;
		else if (t < 2 / 2.75)
			return 7.5625 * (t - 0.545455) * (t - 0.545455) + 0.75;
		else if (t < 2.5 / 2.75)
			return 7.5625 * (t - 0.818182) * (t - 0.818182) + 0.9375;
		else
			return 7.5625 * (t - 0.954545) * (t - 0.954545) + 0.984375;
	}
	public static var InOutBounce = (t:Float) -> t < 0.5 ? (1 - Easing.OutBounce(1 - 2 * t)) / 2 : (1 + Easing.OutBounce(2 * t - 1)) / 2;
	public static var OutInBounce = (t:Float) -> t < 0.5 ? 0.5 * Easing.OutBounce(2 * t) : 0.5 * (1 - Easing.OutBounce(2 - 2 * t) + 1);
}
