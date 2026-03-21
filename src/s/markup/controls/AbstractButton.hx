// package s.markup.controls;

// import s.input.Mouse;

// class AbstractButton<B:Element, C:Element> extends Control<B, C> {
// 	@:signal public var pressed:Bool = false;

// 	public var pressX(default, null):Float = 0.0;
// 	public var pressY(default, null):Float = 0.0;

// 	@:signal public function cancelled();

// 	public function new() {
// 		super();
// 	}

// 	@:slot(mouseEntered)
// 	function __syncMouseEntered__(x, y) {
// 		hovered = true;
// 	}

// 	@:slot(mouseExited)
// 	function __syncMouseExited__(x, y) {
// 		hovered = false;
// 		if (pressed)
// 			cancelled();
// 	}

// 	@:slot(mousePressed)
// 	function __syncMousePressed__(m:MouseButtonEvent) {
// 		var p = mapFromGlobal(m.x, m.y);
// 		pressX = p.x;
// 		pressY = p.y;
// 		pressed = true;
// 	}

// 	@:slot(mouseReleased)
// 	function __syncMouseReleased__(m:MouseButtonEvent) {
// 		pressed = false;
// 	}
// }
