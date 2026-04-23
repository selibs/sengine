package s.ui.positioners;

class Column extends Positioner {
	override function updateChildren()
		s.ui.macro.PositionerMacro.updatePositionFlow("vertical");
}
