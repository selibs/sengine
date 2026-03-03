package se.animation;

class ColorAnimation extends Animation<Color> {
	function update(t:Float):Color {
		return se.math.SMath.mix(from.RGBA, to.RGBA, t);
	}
}
