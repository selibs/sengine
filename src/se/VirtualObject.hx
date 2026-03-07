package se;

#if !macro
@:build(se.macro.SMacro.build())
@:autoBuild(se.macro.SMacro.build())
#end
abstract class VirtualObject<T:VirtualObject<T>> {
	var _parent:T;

	@track public var name:String;
	public var parent(get, set):T;
	public var children(default, null):Array<T>;

	@:signal function parentChanged(previous:T):Void;

	@:signal function childAdded(child:T):Void;

	@:signal function childRemoved(child:T):Void;

	@:signal function descendantAdded(descendant:T):Void;

	@:signal function descendantRemoved(descendant:T):Void;

	public function new() {
		children = new Array(cast this);
	}

	public function setParent(value:T):Void {
		parent = value;
	}

	public function removeParent():Void {
		parent = null;
	}

	public function addChild(value:T) {
		return children.push(value);
	}

	public function removeChild(value:T) {
		return children.remove(value);
	}

	public function getChild(name:String):T {
		for (c in children)
			if (c.name == name)
				return c;
		return null;
	}

	public function getChildren(name:String):List<T> {
		return children.filter(e -> e.name == name);
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

	public function toString():String {
		return '${Type.getClassName(Type.getClass(this))} $name';
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

private typedef List<T> = std.Array<T>;

@:access(se.VirtualObject)
@:forward.new
private abstract Array<T:VirtualObject<T>>(ArrayData<T>) to ArrayData<T> {
	var list(get, never):List<T>;
	var element(get, never):T;

	@:to
	function toArray():List<T> {
		return list.copy();
	}

	public var length(get, never):Int;

	public function excluded(x:T) {
		return copy().remove(x);
	}

	public function concat(a:List<T>):List<T> {
		return list.concat(a);
	}

	public function join(sep:String):String {
		return list.join(sep);
	}

	public function pop():Null<T> {
		return inline rem(list.pop());
	}

	public function push(x:T):Bool {
		if (contains(x))
			return false;
		list.push(x);
		return inline add(x);
	}

	public function reverse():Void {
		list.reverse();
	}

	public function shift():Null<T> {
		return inline rem(list.shift());
	}

	public function slice(pos:Int, ?end:Int):List<T> {
		return list.slice(pos, end);
	}

	public function sort(f:T->T->Int):Void {
		list.sort(f);
	}

	public function splice(pos:Int, len:Int):List<T> {
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
		return inline add(x);
	}

	public function insert(pos:Int, x:T):Bool {
		if (contains(x))
			return false;
		list.insert(pos, x);
		return inline add(x);
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

	public function copy():List<T> {
		return list.copy();
	}

	public function iterator():haxe.iterators.ArrayIterator<T> {
		return list.iterator();
	}

	public function keyValueIterator():haxe.iterators.ArrayKeyValueIterator<T> {
		return list.keyValueIterator();
	}

	public function map<S>(f:T->S):List<S> {
		return list.map(f);
	}

	public function filter(f:T->Bool):List<T> {
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

	inline function add(x:T) {
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

	inline function get_list():List<T> {
		return this.list;
	}

	inline function get_element():T {
		return this.element;
	}
}

private class ArrayData<T:VirtualObject<T>> {
	public var element:T;
	public var list:List<T> = [];

	public function new(element:T) {
		this.element = element;
	}
}
