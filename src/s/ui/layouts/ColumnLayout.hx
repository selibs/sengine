package s.ui.layouts;

import s.ui.Direction;
import s.ui.Element;

class ColumnLayout extends FlowLayout {
	override function updateChildren()
		s.ui.macro.LayoutMacro.updateLayoutFlow("vertical", false, layoutDirection.matches(RightToLeft));

	override function layoutChild(c:Element) {}
}
