package s;

import haxe.Json;

/**
 * Generic tree node with parent/child relationships and hierarchy change signals.
 *
 * The type parameter represents the concrete node type stored in the hierarchy.
 * This is the base structural container used by higher-level scene and markup
 * objects in the engine.
 *
 * The class is intentionally small:
 * - it manages parent and child ownership
 * - it provides tag-based lookup helpers
 * - it emits hierarchy change signals
 *
 * It does not define transform, rendering, or update behavior on its own.
 */
@:allow(s.ObjectList)
abstract class Object<T:Object<T>> implements s.shortcut.Shortcut {
	/**
	 * Parent node or `null` if this node is detached.
	 *
	 * Assigning this field re-parents the node. Most code should use
	 * [`setParent`](s.Object.setParent), [`removeParent`](s.Object.removeParent),
	 * [`addChild`](s.Object.addChild), or [`removeChild`](s.Object.removeChild)
	 * instead of mutating internal storage directly.
	 */
	@:attr(hierarchy) public var parent(default, set):T;

	/**
	 * Direct child nodes.
	 *
	 * The list manages ownership: adding a node here updates its parent, and
	 * removing it detaches it.
	 */
	@:attr.attached public final children:ObjectList<T>;

	/** Creates an empty node with no parent and no children. */
	public function new() {
		children = new ObjectList(cast this);
	}

	/**
	 * Sets the parent node.
	 *
	 * This is equivalent to adding the node to `value.children`.
	 *
	 * @param value New parent node.
	 */
	public function setParent(value:T):Void
		parent = value;

	/** Detaches this node from its parent. */
	public function removeParent():Void
		parent = null;

	/**
	 * Adds a direct child.
	 *
	 * If the child already belongs to another parent, it is re-parented.
	 *
	 * @param value Child node to add.
	 * @return The added child or `null` if it is already present.
	 */
	public function addChild(value:T)
		return children.add(value);

	/**
	 * Removes a direct child.
	 *
	 * @param value Child node to remove.
	 * @return `true` if the child was removed.
	 */
	public function removeChild(value:T)
		return children.remove(value);

	/** Returns an iterator over direct children. */
	public function iterator()
		return children.iterator();

	/**
	 * Traverses all descendants depth-first and applies a callback.
	 *
	 * The callback receives each descendant, not the root node itself.
	 *
	 * @param f Callback invoked for each descendant.
	 * @return This node.
	 */
	public function traverse(f:T->Void) {
		for (child in children)
			f(child.traverse(f));
		return cast this;
	}

	/** Returns a debug-friendly string containing the class name and tag. */
	public function toString():String
		return Type.getClassName(Type.getClass(this));

	function set_parent(value:T):T {
		if (value != null)
			value.addChild(cast this);
		else if (parent != null)
			parent.removeChild(cast this);
		return value;
	}

	function set_dirty(value:Bool) {
		if (value && parent != null && !parent.dirty)
			parent.dirty = true;
		return dirty = value;
	}
}

@:allow(s.Object)
@:forward()
@:forward.new
private extern abstract ObjectList<T:Object<T>>(ObjectListData<T>) to ObjectListData<T> {
	private var dirty(get, set):Bool;
	private var object(get, never):T;
	private var list(get, never):Array<T>;

	public var count(get, never):Int;

	public inline function excluded(x:T)
		return copy().remove(x);

	public inline function concat(a:Array<T>):Array<T>
		return list.concat(a);

	public inline function join(sep:String):String
		return list.join(sep);

	public inline function pop():Null<T>
		return setObjectParent(list.pop(), null);

	public inline function add(x:T):T {
		if (contains(x))
			return null;
		list.push(x);
		return setObjectParent(x, object);
	}

	public inline function reverse():Void
		list.reverse();

	public inline function shift():Null<T>
		return setObjectParent(list.shift(), null);

	public inline function slice(pos:Int, ?end:Int):Array<T>
		return list.slice(pos, end);

	public inline function sort(f:T->T->Int):Void
		list.sort(f);

	public inline function splice(pos:Int, len:Int):Array<T> {
		var els = list.splice(pos, len);
		for (x in els)
			setObjectParent(x, null);
		return els;
	}

	public inline function toString():String
		return list.toString();

	public inline function unshift(x:T):T {
		if (contains(x))
			return null;
		list.unshift(x);
		return setObjectParent(x, object);
	}

	public inline function insert(pos:Int, x:T):T {
		if (contains(x))
			return null;
		list.insert(pos, x);
		return setObjectParent(x, object);
	}

	public inline function remove(x:T):Bool {
		var r = list.remove(x);
		if (r)
			setObjectParent(x, null);
		return r;
	}

	public inline function contains(x:T):Bool
		return x?.parent == object;

	public inline function indexOf(x:T, ?fromIndex:Int):Int
		return list.indexOf(x, fromIndex);

	public inline function lastIndexOf(x:T, ?fromIndex:Int):Int
		return list.lastIndexOf(x, fromIndex);

	@:to
	public inline function copy():Array<T>
		return list.copy();

	public inline function iterator():haxe.iterators.ArrayIterator<T>
		return list.iterator();

	public inline function keyValueIterator():haxe.iterators.ArrayKeyValueIterator<T>
		return list.keyValueIterator();

	public inline function map<S>(f:T->S):Array<S>
		return list.map(f);

	public inline function filter(f:T->Bool):Array<T>
		return list.filter(f);

	public inline function clear() @:privateAccess {
		if (count == 0)
			return;

		dirty = true;
		while (count > 0) {
			final x = list.pop();
			x.parentDirty = true;
			@:bypassAccessor x.parent = null;
		}
	}

	@:op([])
	private inline function arrayRead(i:Int):T
		return list[i];

	@:op([])
	private inline function arrayWrite(i:Int, x:T):T {
		if (!contains(x))
			list[i] = x;
		return x;
	}

	private inline function setObjectParent(x:T, p:T) @:privateAccess {
		if (x != null) {
			dirty = true;
			x.parentDirty = true;
			@:bypassAccessor x.parent = p;
		}
		return x;
	}

	private inline function get_dirty()
		return @:privateAccess this.dirty;

	private inline function set_dirty(value:Bool)
		return @:privateAccess this.dirty = value;

	private inline function get_object()
		return @:privateAccess this.object;

	private inline function get_list()
		return @:privateAccess this.list;

	private inline function get_count():Int
		return list.length;
}

private class ObjectListData<T:Object<T>> extends s.shortcut.AttachedAttribute<T> {
	var list:Array<T> = [];
}
