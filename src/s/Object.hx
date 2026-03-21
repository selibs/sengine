package s;

import haxe.Json;

abstract class Object<T:Object<T>> implements s.shortcut.Shortcut {
	var _parent:T;

	@:attr public var tag:String;

	public var parent(get, set):T;
	public var children(default, null):ObjectList<T>;

	@:signal public function parentChanged(previous:T):Void;

	@:signal public function childAdded(child:T):Void;

	@:signal public function childRemoved(child:T):Void;

	@:signal public function descendantAdded(descendant:T):Void;

	@:signal public function descendantRemoved(descendant:T):Void;

	public function new() {
		children = new ObjectList(cast this);
	}

	public function setParent(value:T):Void {
		parent = value;
	}

	public function removeParent():Void {
		parent = null;
	}

	public function addChild(value:T) {
		return children.add(value);
	}

	public function removeChild(value:T) {
		return children.remove(value);
	}

	public function getChild(tag:String):T {
		for (c in children)
			if (c.tag == tag)
				return c;
		return null;
	}

	public function getChildren(tag:String):Array<T> {
		return children.filter(e -> e.tag == tag);
	}

	public function findChild(tag:String):T {
		for (child in children)
			if (child.tag == tag)
				return child;
			else {
				var c = child.findChild(tag);
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

	public function toString():String {
		return '${Type.getClassName(Type.getClass(this))} #$tag';
	}

	@:slot(childAdded, descendantAdded)
	function __childAdded__(child:T) {
		parent?.descendantAdded(child);
	}

	@:slot(childRemoved, descendantRemoved)
	function __childRemoved__(child:T) {
		parent?.descendantRemoved(child);
	}

	function get_parent():T {
		return _parent;
	}

	function set_parent(value:T):T {
		if (value != null)
			value.addChild(cast this);
		else if (_parent != null)
			_parent.removeChild(cast this);
		return value;
	}
}

@:access(s.Object)
@:forward.new
private extern abstract ObjectList<T:Object<T>>(ArrayData<T>) to ArrayData<T> {
	var list(get, never):Array<T>;
	var element(get, never):T;

	@:to
	inline function toArray():Array<T> {
		return list.copy();
	}

	public var length(get, never):Int;

	public inline function excluded(x:T) {
		return copy().remove(x);
	}

	public inline function concat(a:Array<T>):Array<T> {
		return list.concat(a);
	}

	public inline function join(sep:String):String {
		return list.join(sep);
	}

	public inline function pop():Null<T> {
		return inline rem(list.pop());
	}

	public inline function add(x:T):T {
		if (contains(x))
			return null;
		list.push(x);
		return inline addEl(x);
	}

	public inline function reverse():Void {
		list.reverse();
	}

	public inline function shift():Null<T> {
		return inline rem(list.shift());
	}

	public inline function slice(pos:Int, ?end:Int):Array<T> {
		return list.slice(pos, end);
	}

	public inline function sort(f:T->T->Int):Void {
		list.sort(f);
	}

	public inline function splice(pos:Int, len:Int):Array<T> {
		var els = list.splice(pos, len);
		for (x in els)
			inline rem(x);
		return els;
	}

	public inline function toString():String {
		return list.toString();
	}

	public inline function unshift(x:T):T {
		if (contains(x))
			return null;
		list.unshift(x);
		return inline addEl(x);
	}

	public inline function insert(pos:Int, x:T):T {
		if (contains(x))
			return null;
		list.insert(pos, x);
		return inline addEl(x);
	}

	public inline function remove(x:T):Bool {
		var r = list.remove(x);
		if (r)
			inline rem(x);
		return r;
	}

	public inline function contains(x:T):Bool {
		return x?._parent == this.element;
	}

	public inline function indexOf(x:T, ?fromIndex:Int):Int {
		return list.indexOf(x, fromIndex);
	}

	public inline function lastIndexOf(x:T, ?fromIndex:Int):Int {
		return list.lastIndexOf(x, fromIndex);
	}

	public inline function copy():Array<T> {
		return list.copy();
	}

	public inline function iterator():haxe.iterators.ArrayIterator<T> {
		return list.iterator();
	}

	public inline function keyValueIterator():haxe.iterators.ArrayKeyValueIterator<T> {
		return list.keyValueIterator();
	}

	public inline function map<S>(f:T->S):Array<S> {
		return list.map(f);
	}

	public inline function filter(f:T->Bool):Array<T> {
		return list.filter(f);
	}

	@:op([])
	inline function arrayRead(i:Int):T {
		return list[i];
	}

	@:op([])
	inline function arrayWrite(i:Int, x:T):T {
		if (!contains(x))
			list[i] = x;
		return x;
	}

	inline function addEl(x:T) {
		if (x == null)
			return null;
		var prev = x._parent;
		x._parent = this.element;
		if (prev != null)
			prev.childRemoved(x);
		this.element.childAdded(x);
		x.parentChanged(prev);
		return x;
	}

	inline function get_length():Int {
		return list.length;
	}

	inline function rem(x:T) {
		if (x != null) {
			var prev = x._parent;
			x._parent = null;
			this.element.childRemoved(x);
			x.parentChanged(prev);
		}
		return x;
	}

	inline function get_list():Array<T> {
		return this.list;
	}

	inline function get_element():T {
		return this.element;
	}
}

private class ArrayData<T:Object<T>> {
	public var element:T;
	public var list:Array<T> = [];

	public function new(element:T) {
		this.element = element;
	}
}
