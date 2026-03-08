package se;

#if !macro
@:build(se.macro.SMacro.build())
@:autoBuild(se.macro.SMacro.build())
#end
abstract class Object<T:Object<T>> {
	var _parent:T;

	@track public var tag:String = "object";
	public var parent(get, set):T;
	public var children(default, null):ObjectList<T>;

	@:signal function parentChanged(previous:T):Void;

	@:signal function childAdded(child:T):Void;

	@:signal function childRemoved(child:T):Void;

	@:signal function descendantAdded(descendant:T):Void;

	@:signal function descendantRemoved(descendant:T):Void;

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

@:access(se.Object)
@:forward.new
private abstract ObjectList<T:Object<T>>(ArrayData<T>) to ArrayData<T> {
	var list(get, never):Array<T>;
	var element(get, never):T;

	@:to
	function toArray():Array<T> {
		return list.copy();
	}

	public var length(get, never):Int;

	public function excluded(x:T) {
		return copy().remove(x);
	}

	public function concat(a:Array<T>):Array<T> {
		return list.concat(a);
	}

	public function join(sep:String):String {
		return list.join(sep);
	}

	public function pop():Null<T> {
		return inline rem(list.pop());
	}

	public function add(x:T):Bool {
		if (contains(x))
			return false;
		list.push(x);
		return inline addEl(x);
	}

	public function reverse():Void {
		list.reverse();
	}

	public function shift():Null<T> {
		return inline rem(list.shift());
	}

	public function slice(pos:Int, ?end:Int):Array<T> {
		return list.slice(pos, end);
	}

	public function sort(f:T->T->Int):Void {
		list.sort(f);
	}

	public function splice(pos:Int, len:Int):Array<T> {
		var els = list.splice(pos, len);
		for (x in els)
			inline rem(x);
		return els;
	}

	public function toString():String {
		return list.toString();
	}

	public function unshift(x:T):Bool {
		if (contains(x))
			return false;
		list.unshift(x);
		return inline addEl(x);
	}

	public function insert(pos:Int, x:T):Bool {
		if (contains(x))
			return false;
		list.insert(pos, x);
		return inline addEl(x);
	}

	public function remove(x:T):Bool {
		var r = list.remove(x);
		if (r)
			inline rem(x);
		return r;
	}

	public function contains(x:T):Bool {
		return x?._parent == this.element;
	}

	public function indexOf(x:T, ?fromIndex:Int):Int {
		return list.indexOf(x, fromIndex);
	}

	public function lastIndexOf(x:T, ?fromIndex:Int):Int {
		return list.lastIndexOf(x, fromIndex);
	}

	public function copy():Array<T> {
		return list.copy();
	}

	public function iterator():haxe.iterators.ArrayIterator<T> {
		return list.iterator();
	}

	public function keyValueIterator():haxe.iterators.ArrayKeyValueIterator<T> {
		return list.keyValueIterator();
	}

	public function map<S>(f:T->S):Array<S> {
		return list.map(f);
	}

	public function filter(f:T->Bool):Array<T> {
		return list.filter(f);
	}

	@:op([])
	function arrayRead(i:Int):T {
		return list[i];
	}

	@:op([])
	function arrayWrite(i:Int, x:T):T {
		if (!contains(x))
			list[i] = x;
		return x;
	}

	inline function addEl(x:T) {
		if (x == null)
			return false;
		var prev = x._parent;
		x._parent = this.element;
		if (prev != null)
			prev.childRemoved(x);
		this.element.childAdded(x);
		x.parentChanged(prev);
		return true;
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
