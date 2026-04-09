package s.ui.elements.positioners;

import s.ui.Direction;

abstract class Positioner extends ContainerElement {
	var flowDirty:Bool = false;

	@:attr(flowLayout) public var direction:Direction;
	@:attr(flowLayout) public var spacing:Float = 10.0;

	public function new(direction:Direction) {
		super();
		this.direction = direction;
	}
}
