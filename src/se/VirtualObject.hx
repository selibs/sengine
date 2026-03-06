package se;

#if !macro
@:build(se.macro.SMacro.build())
@:autoBuild(se.macro.SMacro.build())
#end
abstract class VirtualObject<T:VirtualObject<T>> {
	public var name:String;
	public var children:Array<T> = [];
	@:isVar public var parent(default, set):T;

	@:signal function childAdded(child:T):Void;

	@:signal function childRemoved(child:T):Void;

	@:signal function parentChanged(previous:T):Void;

	public function setParent(value:T):Void {
		parent = value;
	}

	public function removeParent():Void {
		parent = null;
	}

	public function addChild(value:T):T {
		if (value != null)
			value.parent = cast this;
		return value;
	}

	public function getChild(name:String):T {
		for (c in children)
			if (c.name == name)
				return c;
		return null;
	}

	public function findChild(name:String):T {
		for (child in children)
			if (child.name == name)
				return child;
			else {
				var c = child.findChild(name);
				if (c != null)
					return c;
			}
		return null;
	}

	public function iterator() {
		return children.iterator();
	}

	public function traverse(f:T->Void) {
		for (child in children)
			f(child.traverse(f));
		return cast this;
	}

	public function removeChild(value:T):Void {
		if (value != null && children.contains(value))
			value.parent = null;
	}

	public function toString():String {
		return '${Type.getClassName(Type.getClass(this))} $name';
	}

	function set_parent(value:T):T {
		if (value != parent) {
			var removed:Bool = false;
			var added:Bool = false;

			if (parent != null && parent.children.contains(cast this)) {
				parent.children.remove(cast this);
				removed = true;
			}
			if (value != null && !value.children.contains(cast this)) {
				value.children.push(cast this);
				added = true;
			}

			var prev = parent;
			parent = value;
			parentChanged(prev);
			if (removed)
				prev.childRemoved(cast this);
			if (added)
				parent.childAdded(cast this);
		}
		return value;
	}
}

private abstract VirtualObjectList<T:VirtualObject<T>>(VirtualObjectListData<T>) {
	var length(get, never):Int;

	public function new():Void;

	public function concat(a:Array<T>):Array<T> {
		return this.list.concat(a);
	}

	public function join(sep:String):String {
		return this.list.join(sep);
	}

	public function pop():Null<T> {
		var c = this.list.pop();
		if (c != null)
			c.parent = this.el;
		return c;
	}

	public function push(x:T):Int {
		x.parent = this.el;
		return this.list.length;
	}

	/**
		Reverse the order of elements of `this` Array.

		This operation modifies `this` Array in place.

		If `this.length < 2`, `this` remains unchanged.
	**/
	public function reverse():Void;

	public function shift():Null<T> {
		var c = this.list.shift();
		if (c != null)
			c.parent = this.el;
		return c;
	}

	public function slice(pos:Int, ?end:Int):Array<T> {
		return this.list.slice(pos, end);
	}

	public function sort(f:T->T->Int):Void {
		this.list.sort(f);
	}

	/**
		Removes `len` elements from `this` Array, starting at and including
		`pos`, an returns them.

		This operation modifies `this` Array in place.

		If `len` is < 0 or `pos` exceeds `this`.length, an empty Array [] is
		returned and `this` Array is unchanged.

		If `pos` is negative, its value is calculated from the end	of `this`
		Array by `this.length + pos`. If this yields a negative value, 0 is
		used instead.

		If the sum of the resulting values for `len` and `pos` exceed
		`this.length`, this operation will affect the elements from `pos` to the
		end of `this` Array.

		The length of the returned Array is equal to the new length of `this`
		Array subtracted from the original length of `this` Array. In other
		words, each element of the original `this` Array either remains in
		`this` Array or becomes an element of the returned Array.
	**/
	public function splice(pos:Int, len:Int):Array<T>;

	public function toString():String {
		return this.list.toString();
	}

	/**
		Adds the element `x` at the start of `this` Array.

		This operation modifies `this` Array in place.

		`this.length` and the index of each Array element increases by 1.
	**/
	public function unshift(x:T):Void;

	/**
		Inserts the element `x` at the position `pos`.

		This operation modifies `this` Array in place.

		The offset is calculated like so:

		- If `pos` exceeds `this.length`, the offset is `this.length`.
		- If `pos` is negative, the offset is calculated from the end of `this`
		  Array, i.e. `this.length + pos`. If this yields a negative value, the
		  offset is 0.
		- Otherwise, the offset is `pos`.

		If the resulting offset does not exceed `this.length`, all elements from
		and including that offset to the end of `this` Array are moved one index
		ahead.
	**/
	public function insert(pos:Int, x:T):Void;

	public function remove(x:T):Bool {
		if (this.list.contains(x))
			return this.list.remove(x);
		return false;
	}

	/**
		Returns whether `this` Array contains `x`.

		If `x` is found by checking standard equality, the function returns `true`, otherwise
		the function returns `false`.
	**/
	public function contains(x:T):Bool;

	/**
		Returns position of the first occurrence of `x` in `this` Array, searching front to back.

		If `x` is found by checking standard equality, the function returns its index.

		If `x` is not found, the function returns -1.

		If `fromIndex` is specified, it will be used as the starting index to search from,
		otherwise search starts with zero index. If it is negative, it will be taken as the
		offset from the end of `this` Array to compute the starting index. If given or computed
		starting index is less than 0, the whole array will be searched, if it is greater than
		or equal to the length of `this` Array, the function returns -1.
	**/
	public function indexOf(x:T, ?fromIndex:Int):Int;

	/**
		Returns position of the last occurrence of `x` in `this` Array, searching back to front.

		If `x` is found by checking standard equality, the function returns its index.

		If `x` is not found, the function returns -1.

		If `fromIndex` is specified, it will be used as the starting index to search from,
		otherwise search starts with the last element index. If it is negative, it will be
		taken as the offset from the end of `this` Array to compute the starting index. If
		given or computed starting index is greater than or equal to the length of `this` Array,
		the whole array will be searched, if it is less than 0, the function returns -1.
	**/
	public function lastIndexOf(x:T, ?fromIndex:Int):Int;

	/**
		Returns a shallow copy of `this` Array.

		The elements are not copied and retain their identity, so
		`a[i] == a.copy()[i]` is true for any valid `i`. However,
		`a == a.copy()` is always false.
	**/
	public function copy():Array<T>;

	/**
		Returns an iterator of the Array values.
	**/
	public inline function iterator():haxe.iterators.ArrayIterator<T> {
		return new haxe.iterators.ArrayIterator(this);
	}

	/**
		Returns an iterator of the Array indices and values.
	**/
	public public inline function keyValueIterator():ArrayKeyValueIterator<T> {
		return new ArrayKeyValueIterator(this);
	}

	/**
		Creates a new Array by applying function `f` to all elements of `this`.

		The order of elements is preserved.

		If `f` is null, the result is unspecified.
	**/
	public inline function map<S>(f:T->S):Array<S> {
		#if (cpp && !cppia)
		var result = cpp.NativeArray.create(length);
		for (i in 0...length)
			cpp.NativeArray.unsafeSet(result, i, f(cpp.NativeArray.unsafeGet(this, i)));
		return result;
		#else
		return [for (v in this) f(v)];
		#end
	}

	/**
		Returns an Array containing those elements of `this` for which `f`
		returned true.

		The individual elements are not duplicated and retain their identity.

		If `f` is null, the result is unspecified.
	**/
	public inline function filter(f:T->Bool):Array<T> {
		return [for (v in this) if (f(v)) v];
	}

	/**
		Set the length of the Array.

		If `len` is shorter than the array's current size, the last
		`length - len` elements will be removed. If `len` is longer, the Array
		will be extended, with new elements set to a target-specific default
		value:

		- always null on dynamic targets
		- 0, 0.0 or false for Int, Float and Bool respectively on static targets
		- null for other types on static targets
	**/
	public function resize(len:Int):Void;
}

private class VirtualObjectListData<T:VirtualObject<T>> {
	var list:Array<T> = [];
	var el:T;

	public function new(el:T) {
		this.el = el;
	}
}
