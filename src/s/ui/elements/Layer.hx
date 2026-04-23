package s.ui.elements;

import s.ui.elements.Drawable;

@:allow(s.ui.elements.Drawable)
class Layer extends Canvas {
	var paintDirty:Bool = false;

	final drawable:Array<Drawable> = [];

	public var isLive:Bool = true;

	override function setChildLayer(child:Element)
		@:bypassAccessor child.layer = this;

	override function update() {
		super.update();

		paintDirty = paintDirty || dirty;
		if (children.dirty)
			drawable.resize(0);
	}

	override function updateTree() {
		if (!dirty)
			return;

		super.updateTree();

		if (paintDirty) {
			paintDirty = false;
			if (isLive)
				paint(_ -> for (el in drawable)
					el.draw(texture));
		}
	}

	override function set_dirty(value:Bool) {
		if (value)
			paintDirty = true;
		return super.set_dirty(value);
	}
}
