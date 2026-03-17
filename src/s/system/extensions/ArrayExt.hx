package s.system.extensions;

class ArrayExt {
	public static function last<T>(a:Array<T>):T {
		return a[a.length - 1];
	}

	public static function min(a:Array<Float>) {
		var m = a[0];
		for (x in a)
			m = Math.min(x, m);
		return m;
	}

	public static function max(a:Array<Float>) {
		var m = a[0];
		for (x in a)
			m = Math.max(x, m);
		return m;
	}
}
