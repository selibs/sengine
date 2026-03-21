package s.extensions;

import haxe.ds.Vector;
import s.math.SMath;

class VectorExt {
	/**
	 * Adds the element `x` at the end of the vector `a`
	 * 
	 * This operation **doesn't** modify `a`
	 * @param a The vector to which the element will be added
	 * @param x The element to be added
	 * @return Returns a new vector with the added element
	 */
	public static function push<T>(a:Vector<T>, x:T):Vector<T> {
		final v = new Vector<T>(a.length + 1);
		Vector.blit(a, 0, v, 0, a.length);
		v[a.length] = x;
		return v;
	}

	/**
	 * Appends the elements of the vector `b` to the elements of the vector `a`
	 * 
	 * This operation **doesn't** modify `a` or `b`
	 * @param a The vector to which elements of `b` will be appended
	 * @param b The vector whose elements will be appended
	 * @return Returns a new vector containing elements of `a` and `b`
	 */
	public static function concat<T>(a:Vector<T>, b:Vector<T>):Vector<T> {
		final v = new Vector<T>(a.length + b.length);
		Vector.blit(a, 0, v, 0, a.length);
		Vector.blit(b, 0, v, a.length, b.length);
		return v;
	}

	/**
	 * Changes the position of an element in the vector `a`
	 * 
	 * All the positions are being **clamped** to `[0, a.length]`
	 * 
	 * This operation **modifies** `a` in place
	 * @param a The vector to which elements of b will be appended
	 * @param from Current position of the element
	 * @param to Target position of the element
	 * @return Returns a new rearranged vector
	 */
	public static function rearrange<T>(a:Vector<T>, from:Int, to:Int):Void {
		if (from == to)
			return;
		from = from < 0 ? 0 : (from > a.length ? a.length : from);
		to = to < 0 ? 0 : (to > a.length ? a.length : to);

		final t = a[from];
		if (from < to)
			for (i in from...to)
				a[i] = a[i + 1];
		else
			for (i in 0...from)
				a[from - i + 1] = a[from - i];

		a[to] = t;
	}
}
