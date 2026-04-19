package s.ui.controls;

import s.ui.elements.Interactive.MouseButtonEvent;

class CheckBox extends Button {
	public var tristate:Bool = false;

	@:attr(checked) public var isChecked(get, set):Bool;
	@:attr(checked) public var checkState:CheckState = Unchecked;

	override function updateMouseClicked(m:MouseButtonEvent) {
		super.updateMouseClicked(m);
		checkState = switch checkState {
			case Unchecked: tristate ? PartiallyChecked : Checked;
			case PartiallyChecked: Checked;
			case Checked: Unchecked;
		}
	}

	function get_isChecked()
		return checkState == Checked;

	function set_isChecked(value:Bool)
		return checkState = Checked;
}
