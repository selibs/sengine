package s.ui;

import s.ui.elements.Element;

class HorizontalAnchor extends AnchorLineAttribute {}
class VerticalAnchor extends AnchorLineAttribute {}

@:allow(s.ui.AnchorsAttribute)
@:allow(s.ui.elements.Element)
abstract class AnchorLineAttribute extends s.shortcut.AttachedAttribute<Element> {
	final dependents:Array<Element> = [];

	@:attr(offset) public var position:Float = 0.0;
	@:attr(offset) public var padding:Float = 0.0;
	@:attr public var margin:Float = 0.0;

	function set_position(value:Float):Float {
		if (value == position)
			return position;
		position = value;
		markDependentsDirty();
		return position;
	}

	function set_padding(value:Float):Float {
		if (value == padding)
			return padding;
		padding = value;
		markDependentsDirty();
		return padding;
	}

	inline function addDependent(el:Element)
		if (!dependents.contains(el))
			dependents.push(el);

	inline function removeDependent(el:Element)
		dependents.remove(el);

	@:access(s.ui.elements.Element)
	inline function markDependentsDirty()
		for (d in dependents)
			if (!d.dirty)
				d.dirty = true;
}
