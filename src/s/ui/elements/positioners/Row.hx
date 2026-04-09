package s.ui.elements.positioners;

import s.ui.Direction;

class Row extends Positioner {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	function syncFlow() {
		s.ui.macro.PositionerMacro.syncPositionerFlow("left", "right");
	}
}
