package se.animation;

class NumberAnimation extends Animation<Float> {
	function mix(t:Float):Float {
		return se.math.SMath.mix(from, to, t);
	}
}
