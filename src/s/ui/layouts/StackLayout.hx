package s.ui.layouts;

class StackLayout extends Layout {
	public var current(default, null):Element;

	@:readonly @:alias extern public var count:Int = children.count;

	@:attr public var currentIndex:Int = 0;

	override function updateChildren() {
		final c = current;
		if (c != null)
			updateChild(c);
	}

	override function update() {
		super.update();

		if (currentIndexDirty || children.dirty) {
			final count = children.count;
			if (count == 0)
				current = null;
			else {
				final index = currentIndex % count;
				current = children[currentIndex >= 0 ? index : (index + count) % count];
			}
		}
	}
}
