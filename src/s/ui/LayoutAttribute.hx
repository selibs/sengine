package s.ui;

import s.ui.Alignment;
import s.ui.elements.Element;

@:allow(s.ui.elements.Element)
class LayoutAttribute extends s.shortcut.AttachedAttribute<Element> {
	@:attr public var alignment:Alignment = AlignCenter;
	@:attr(horizontal) public var fillWidth:Bool = false;
	@:attr(vertical) public var fillHeight:Bool = false;
	@:attr(horizontal) public var minimumWidth:Float = 0.0;
	@:attr(horizontal) public var maximumWidth:Float = Math.POSITIVE_INFINITY;
	@:attr(vertical) public var minimumHeight:Float = 0.0;
	@:attr(vertical) public var maximumHeight:Float = Math.POSITIVE_INFINITY;
	@:attr(horizontal) public var preferredWidth:Float = Math.NaN;
	@:attr(vertical) public var preferredHeight:Float = Math.NaN;
	@:attr(horizontal, distribution) @:clamp(0) public var fillWidthFactor(default, set):Float = 1.0;
	@:attr(vertical, distribution) @:clamp(0) public var fillHeightFactor(default, set):Float = 1.0;

	@:attr(grid) @:clamp(0) public var row(default, set):Int = 0;
	@:attr(grid) @:clamp(1) public var rowSpan(default, set):Int = 1;
	@:attr(grid) @:clamp(0) public var column(default, set):Int = 0;
	@:attr(grid) @:clamp(1) public var columnSpan(default, set):Int = 1;
	@:attr(distribution) public var weight:Float = 1.0;
}
