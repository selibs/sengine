package s.ui.positioners;

class Row extends Positioner {
	override function updateChildren()
		s.ui.macro.PositionerMacro.updatePositionFlow("width", "left", "hCenter", "right", "height", "top", "vCenter", "bottom");
}
