package s.system.animation;

class NumberAnimation extends Animation<Float> {
	function mix(t:Float):Float {
		return s.system.math.SMath.mix(from, to, t);
	}
}
