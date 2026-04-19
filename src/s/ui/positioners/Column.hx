package s.ui.positioners;

import s.ui.Direction;

class Column extends Positioner {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function updateFlow() {
		s.ui.macro.PositionerMacro.updatePositionerFlow("top", "bottom");
	}
}
