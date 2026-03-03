package se.animation;

class NumberAnimation extends Animation<Float> {
	function update(t:Float):Float {
		return se.math.SMath.mix(from, to, t);
	}
}
