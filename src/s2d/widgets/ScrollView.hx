package s2d.widgets;

import se.system.input.Mouse;
import s2d.elements.Flickable;

@:ui.shortcut(scroll)
class ScrollView extends Flickable {
	public var scrollDelta:Float = 10.0;

	public function new(name:String = "scrollView") {
		super(name);
	}

	@:slot(mouseScrolled)
	function scrolled(m:MouseScrollEvent) {
		shiftY -= m.delta * scrollDelta;
	}
}
