package s.ui.layouts;

import s.ui.Direction;

abstract class DirectionalLayout extends Layout {
	@:attr public var spacing:Float = 5.0;
	@:attr public var direction:Direction = LeftToRight | TopToBottom;
	@:attr public var uniformCellSizes:Bool = false;

	public function new(?direction:Direction) {
		super();
		if (direction != null)
			this.direction = direction;
	}
}
