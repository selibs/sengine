package s.ui.elements.positioners;

class Row extends Positioner {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	function syncFlow() {
		s.ui.macro.PositionerMacro.syncPositionerFlow("left", "right");
	}
}
