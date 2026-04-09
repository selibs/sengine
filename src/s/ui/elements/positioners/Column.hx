package s.ui.elements.positioners;

import s.ui.Direction;

class Column extends Positioner {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function syncFlow() {
		s.ui.macro.PositionerMacro.syncPositionerFlow("top", "bottom");
	}
}
