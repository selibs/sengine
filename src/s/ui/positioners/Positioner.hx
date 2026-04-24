package s.ui.positioners;

import s.ui.Direction;
import s.ui.Alignment;

abstract class Positioner extends Element {
	@:attr public var spacing:Float = 5.0;
	@:attr public var direction:Direction = LeftToRight | TopToBottom;
	@:attr public var alignment:Alignment = AlignLeft | AlignTop;

	public function new(?direction:Direction) {
		super();
		if (direction != null)
			this.direction = direction;
	}

	override function updateChildDependencies(child:Element) {
		if (child.parentDirty)
			insertChild(child);
		if (child.parentDirty || sceneDirty)
			setChildScene(child);
		if (child.parentDirty || layerDirty)
			setChildLayer(child);
	}
}
