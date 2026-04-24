package s.ui.layouts;

@:access(s.ui.AttachedLayout)
class ColumnLayout extends DirectionalLayout {
	override function updateChildren()
		s.ui.macro.LayoutMacro.updateLayoutFlow("top", "bottom", "y", "height", "x", "width");
}
