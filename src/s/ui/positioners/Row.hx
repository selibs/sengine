package s.ui.positioners;

import s.ui.Direction;

class Row extends Positioner {
	public function new(direction:Direction = LeftToRight)
		super(direction);

	function updateFlow() {
		if (direction.matches(RightToLeft)) {
			var base = right.position - right.padding;
			for (c in children) {
				c.right.position = base - c.right.margin;
				updateChild(c);
				base = c.left.position;
			}
		} else {
			var base = left.position + left.padding;
			for (c in children) {
				c.left.position = base + c.left.margin;
				updateChild(c);
				base = c.right.position;
			}
		}
	}
}
