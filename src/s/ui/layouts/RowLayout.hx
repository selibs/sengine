package s.ui.layouts;

@:access(s.ui.AttachedLayout)
class RowLayout extends DirectionalLayout {
	override function updateChildren()
		s.ui.macro.LayoutMacro.updateLayoutFlow("horizontal", "left", "right", "x", "width", "y", "height");
}
