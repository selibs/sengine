package s.ui.controls;

import s.ui.shapes.Rectangle;

class Progress extends Control<Rectangle, Rectangle> {
	public var from:Float = 0.0;
	public var to:Float = 1.0;
	public var value:Float = 0.0;
	public var position:Float = 0.0;
	public var indeterminate:Bool = false;

	@:slot(update)
	function updateProgress(_) {}
}
