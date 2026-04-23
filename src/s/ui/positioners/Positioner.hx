package s.ui.positioners;

import s.ui.Direction;

abstract class Positioner extends Element {
	@:attr(flowLayout) public var direction:Direction;
	@:attr(flowLayout) public var spacing:Float = 10.0;

	public function new(direction:Direction) {
		super();
		this.direction = direction;
	}

	override function updateChildren()
		updateFlow();

	abstract function updateFlow():Void;
}
