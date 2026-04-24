package s.ui.layouts;

class StackLayout extends Layout {
	@:attr var el:Element;

	@:readonly @:alias extern public var count:Int = children.count;
	@:readonly @:alias extern public var current:Element = el;

	@:attr public var currentIndex:Int = 0;

	override function update() {
		super.update();

		if (!currentIndexDirty && !children.dirty)
			return;

		final count = children.count;
		if (count == 0)
			el = null;
		else {
			final index = currentIndex % count;
			el = children[currentIndex >= 0 ? index : (index + count) % count];
		}
	}

	override function updateChildren()
		if (elDirty) {
			cells.resize(0);
			if (current != null)
				pushCell(current);
		} else if (cells.length >= 1)
			syncCell(0);
}
