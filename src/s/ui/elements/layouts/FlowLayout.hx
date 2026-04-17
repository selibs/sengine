package s.ui.elements.layouts;

import s.ui.Axis;
import s.ui.Direction;

class FlowLayout extends DirectionalLayout {
	@:attr(flowLayout) public var axis:Axis;

	public function new(axis:Axis = Horizontal, direction:Direction = LeftToRight) {
		super(direction);
		this.axis = axis;
	}

	override function updateChildren() {
		if (flowLayoutDirty)
			flowDirty = true;

		if (axis == Horizontal)
			Layout.updateHorizontalWrap(this);
		else
			Layout.updateVerticalWrap(this);
	}
}
