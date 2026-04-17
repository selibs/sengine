package s.ui.elements.controls;

import s.ui.elements.shapes.Rectangle;

class Progress extends Control<Rectangle, Rectangle> {
	public var from:Float = 0.0;
	public var to:Float = 1.0;
	public var value:Float = 0.0;
	public var position:Float = 0.0;
	public var indeterminate:Bool = false;

    @:slot(update)
    function updateProgress(_) {
        
    }
}
