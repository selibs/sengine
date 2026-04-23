package s.ui.positioners;

import s.ui.Direction;

class Column extends Positioner {
	public function new(direction:Direction = TopToBottom)
		super(direction);

	function updateFlow() {
		if (direction.matches(BottomToTop)) {
			var base = bottom.position - bottom.padding;
			for (c in children) {
				c.bottom.position = base - c.bottom.margin;
				updateChild(c);
				base = c.top.position;
			}
		} else {
			var base = top.position + top.padding;
			for (c in children) {
				c.top.position = base + c.top.margin;
				updateChild(c);
				base = c.bottom.position;
			}
		}
	}
}
