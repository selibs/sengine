package s2d;

enum abstract Length(LengthData) {
	// absolute units
	public static inline function px(value:Float) {
		return new Length(value);
	}

	public static inline function inch(value:Float) {
		return px(value * 96);
	}

	public static inline function cm(value:Float) {
		return inch(value / 2.54);
	}

	public static inline function mm(value:Float) {
		return cm(value / 10);
	}

	public static inline function Q(value:Float) {
		return mm(value / 4);
	}

	public static inline function pc(value:Float) {
		return inch(value / 6);
	}

	public static inline function pt(value:Float) {
		return pc(value / 12);
	}

	// relative units
	// TODO
	@:from
	public static function fromFloat(value:Float) {
		return new Length(value);
	}

	@:to
	public function toFloat():Float {
		return this.value;
	}

	public function new(value:Float) {
		this = {value: value};
	}
}

private typedef LengthData = {value:Float}
