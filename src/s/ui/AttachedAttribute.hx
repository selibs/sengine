package s.ui;

import s.ui.elements.Element;

abstract class AttachedAttribute implements s.shortcut.Shortcut {
	final object:Element;
	var isDirty(default, set):Bool = false;

	public function new(object)
		this.object = object;

	function set_isDirty(value:Bool) {
		if (value && !object.isDirty)
			object.isDirty = true;
		return isDirty = value;
	}
}
