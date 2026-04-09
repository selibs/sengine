package s.ui.elements.layouts;

import s.ui.Direction;

class RowLayout extends DirectionalLayout {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	override function syncChildren()
		Layout.syncHorizontalFlow(this);
}
