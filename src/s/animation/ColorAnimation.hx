package s.animation;

class ColorAnimation extends Animation<Color> {
	function mix(t:Float):Color {
		return s.math.SMath.mix(from.RGBA, to.RGBA, t);
	}
}
