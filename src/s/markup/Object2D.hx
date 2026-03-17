package s.markup;

abstract class Object2D<This:Object2D<This>> extends s.system.Object<This> {
	@:attr public var z(default, set):Float = 0;

	public var transform:Transform2D = Transform2D.identity();

	public function new() {
		super();
	}

	@:slot(childAdded)
	override function __childAdded__(child:This) {
		insertChild(child);
		super.__childAdded__(child);
	}

	function insertChild(child:This) {
		var c = @:privateAccess children.list;
		c.remove(child);
		for (i in 0...c.length)
			if (c[i].z > child.z) {
				c.insert(i, child);
				return;
			}
		c.push(child);
	}

	function set_z(value:Float):Float {
		if (value != z) {
			z = value;
			if (parent != null)
				parent.insertChild(cast this);
		}
		return z;
	}
}
