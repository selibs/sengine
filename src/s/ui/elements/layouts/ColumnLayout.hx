package s.ui.elements.layouts;

import s.ui.Direction;

class ColumnLayout extends DirectionalLayout {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function syncFlow()
		Layout.syncVerticalFlow(this);
}
