package s.ui.elements;

import s.graphics.RenderTarget;

class Stack extends Element {
	public var current(get, never):Element;
	public var currentIndex(default, set):Int = 0;

	override function render(target:RenderTarget) {
		final c = current;
		if (c == null)
			return;
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		Element.renderElement(c, target);
		ctx.style.popOpacity();
	}

	override function syncChildren() {
		sync(this);
		final c = current;
		if (c != null)
			syncChild(c);
		flush();
	}

	inline function get_current():Element
		return currentIndex >= 0 && currentIndex < children.length ? children[currentIndex] : null;

	override function syncChildRemoved(child:Element) {
		super.syncChildRemoved(child);
		if (currentIndex >= children.length)
			currentIndex = children.length - 1;
	}

	inline function set_currentIndex(value:Int):Int
		return currentIndex = value < 0 ? 0 : (value >= children.length ? children.length - 1 : value);
}
