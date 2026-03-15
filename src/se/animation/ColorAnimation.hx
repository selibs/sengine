package se.animation;

class ColorAnimation extends Animation<Color> {
	function mix(t:Float):Color {
		return se.math.SMath.mix(from.RGBA, to.RGBA, t);
	}
}
