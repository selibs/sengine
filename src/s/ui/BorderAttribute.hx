package s.ui;

class BorderAttribute extends s.shortcut.AttachedAttribute<s.ui.shapes.Shape> {
	@:attr(borderVisual) @:clamp(0) public var width:Float = 0.0;
	@:attr(borderVisual) public var color:Color = Transparent;
}
