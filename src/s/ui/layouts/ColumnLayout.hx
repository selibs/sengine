package s.ui.layouts;

import s.ui.Direction;

class ColumnLayout extends DirectionalLayout {
	public function new(direction:Direction = TopToBottom) {
		super(direction);
	}

	function updateFlow()
		Layout.updateVerticalFlow(this);
}
