package s.ui.elements.layouts;

class RowLayout extends DirectionalLayout {
	public function new(direction:Direction = LeftToRight) {
		super(direction);
	}

	function syncFlow()
		s.ui.macro.DirectionalLayoutMacro.syncLayoutFlow(true);
}
