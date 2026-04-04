package s.ui.elements.positioners;

class Column extends Positioner {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function syncFlow() {
		s.ui.macro.PositionerMacro.syncPositionerFlow("top", "bottom");
	}
}
