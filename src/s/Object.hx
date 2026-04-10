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
abstract class Object<T:Object<T>> implements s.shortcut.Shortcut implements s.shortcut.AttributeOwner {
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

	public function markDirty()
		dirty = true;

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
			parent.markDirty();
		return dirty = value;
	}

	function set_hierarchyDirty(value:Bool) {
		if (value && parent != null && !parent.children.dirty)
			parent.children.dirty = true;
		return children.dirty = value;
	}
}
