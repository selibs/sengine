package s.ui.positioners;

class Column extends Positioner {
	override function updateChildren()
		s.ui.macro.PositionerMacro.updatePositionFlow("height", "top", "vCenter", "bottom", "width", "left", "hCenter", "right");
}
