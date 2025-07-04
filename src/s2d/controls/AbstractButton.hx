package s2d.controls;

import se.events.MouseEvents;

class AbstractButton<B:Element, C:Element> extends Control<B, C> {
	@track public var pressed:Bool = false;
	@track public var hovered:Bool = false;

	public var pressX(default, null):Float = 0.0;
	public var pressY(default, null):Float = 0.0;

	@:signal function cancelled();

	public function new(name:String = "button") {
		super(name);
	}

	@:slot(mouseEntered)
	function __syncMouseEntered__(x, y) {
		hovered = true;
	}

	@:slot(mouseExited)
	function __syncMouseExited__(x, y) {
		hovered = false;
		if (pressed)
			cancelled();
	}

	@:slot(mousePressed)
	function __syncMousePressed__(m:MouseButtonEvent) {
		var p = mapFromGlobal(m.x, m.y);
		pressX = p.x;
		pressY = p.y;
		pressed = true;
	}

	@:slot(mouseReleased)
	function __syncMouseReleased__(m:MouseButtonEvent) {
		pressed = false;
	}
}
