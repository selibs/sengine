package s.ui.elements;

import s.graphics.RenderTarget;

class Stack extends Element {
	@:readonly @:alias extern public var current:Element = children[currentIndex];
	public var currentIndex(default, set):Int = 0;

	override function updateChildren() {
		update();
		final c = current;
		if (c != null)
			updateChild(c);
		flush();
	}

	override function updateChildRemoved(child:Element) {
		super.updateChildRemoved(child);
		if (currentIndex >= children.length)
			currentIndex = children.length - 1;
	}

	function set_currentIndex(value:Int):Int
		return currentIndex = value < 0 ? 0 : (value >= children.count ? children.count - 1 : value);
}
