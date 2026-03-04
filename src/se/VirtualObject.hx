package se;

#if !macro
@:build(se.macro.SMacro.build())
@:autoBuild(se.macro.SMacro.build())
#end
abstract class VirtualObject<This:VirtualObject<This>> {
	public var name:String;
	public var children:Array<This> = [];
	@:isVar public var parent(default, set):This;

	@:signal function childAdded(child:This):Void;

	@:signal function childRemoved(child:This):Void;

	@:signal function parentChanged(previous:This):Void;

	public function setParent(value:This):Void {
		parent = value;
	}

	public function removeParent():Void {
		parent = null;
	}

	public function addChild(value:This):Void {
		if (value != null)
			value.parent = cast this;
	}

	public function getChild(name:String):This {
		for (c in children)
			if (c.name == name)
				return c;
		return null;
	}

	public function findChild(name:String):This {
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

	public function removeChild(value:This):Void {
		if (value != null && children.contains(value))
			value.parent = null;
	}

	public function toString():String {
		return '${Type.getClassName(Type.getClass(this))} $name';
	}

	function set_parent(value:This):This {
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
