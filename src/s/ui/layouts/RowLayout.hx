package s.ui.layouts;

import s.ui.Direction;

class RowLayout extends DirectionalLayout {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	override function updateChildren()
		Layout.updateHorizontalFlow(this);
}
