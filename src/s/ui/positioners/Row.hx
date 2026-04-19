package s.ui.positioners;

import s.ui.Direction;

class Row extends Positioner {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	function updateFlow() {
		s.ui.macro.PositionerMacro.updatePositionerFlow("left", "right");
	}
}
