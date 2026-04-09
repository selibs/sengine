package s.ui;

import s.ui.elements.shapes.Shape;

class BorderAttribute extends s.shortcut.AttachedAttribute<Shape> {
	@:attr(borderVisual) @:clamp(0) public var width:Float = 0.0;
	@:attr(borderVisual) public var color:Color = Transparent;
}
