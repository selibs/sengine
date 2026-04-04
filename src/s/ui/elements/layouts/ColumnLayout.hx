package s.ui.elements.layouts;

class ColumnLayout extends DirectionalLayout {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function syncFlow()
		s.ui.macro.DirectionalLayoutMacro.syncLayoutFlow(false);
}
