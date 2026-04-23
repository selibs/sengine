package s.ui.layouts;

import s.ui.Direction;
import s.ui.Element;

class RowLayout extends FlowLayout {
	override function updateChildren()
		s.ui.macro.LayoutMacro.updateLayoutFlow("horizontal", layoutDirection.matches(RightToLeft), layoutDirection.matches(RightToLeft));

	override function layoutChild(c:Element) {}
}
