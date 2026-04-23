package s.ui.positioners;

import s.ui.Direction;
import s.ui.elements.Container;

abstract class Positioner extends Container {
	@:marker var flowDirty:Bool = false;

	@:attr(flowLayout) public var direction:Direction;
	@:attr(flowLayout) public var spacing:Float = 10.0;

	public function new(direction:Direction) {
		super();
		this.direction = direction;
	}

	// TODO: no reflection
	override function updateChildren() {
		final updateFlow = Reflect.field(this, "updateFlow");
		if (updateFlow != null)
			Reflect.callMethod(this, updateFlow, []);
		else
			super.updateChildren();
	}
}
