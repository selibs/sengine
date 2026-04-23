package s.ui.positioners;

class Row extends Positioner {
	override function updateChildren()
		s.ui.macro.PositionerMacro.updatePositionFlow("horizontal");
}
