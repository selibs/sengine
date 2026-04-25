package s.ui;

class BorderAttribute extends s.shortcut.AttachedAttribute<s.ui.shapes.Shape> {
	@:attr public var color:Color = Transparent;
	@:attr public var width:Float = 0.0;
	@:attr @:clamp(0) public var softness:Float = 0.5;
}
