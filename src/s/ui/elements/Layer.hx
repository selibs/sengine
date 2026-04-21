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

		paintDirty = dirty;
		if (children.dirty)
			drawable.resize(0);
	}

	override function updateTree(?styles:Array<Style>, inheritedDirty:Bool = false) {
		super.updateTree(styles, inheritedDirty);

		if (paintDirty) {
			paintDirty = false;
			if (isLive)
				paint(_ -> for (el in drawable)
					el.draw(texture));
		}
	}
}
