package s.animation;

class NumberAnimation extends Animation<Float> {
	function mix(t:Float):Float {
		return s.math.SMath.mix(from, to, t);
	}
}
