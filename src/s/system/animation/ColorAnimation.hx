package s.system.animation;

class ColorAnimation extends Animation<Color> {
	function mix(t:Float):Color {
		return s.system.math.SMath.mix(from.RGBA, to.RGBA, t);
	}
}
