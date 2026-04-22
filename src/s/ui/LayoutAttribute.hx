package s.ui;

import s.ui.Alignment;
import s.ui.Element;

typedef LayoutAttributeAttributes = {
	?row:Int,
	?rowSpan:Int,
	?column:Int,
	?columnSpan:Int,
	?weight:Float,
	?alignment:Alignment,
	?fillWidth:Bool,
	?fillHeight:Bool,
	?minimumWidth:Float,
	?maximumWidth:Float,
	?minimumHeight:Float,
	?maximumHeight:Float,
	?preferredWidth:Float,
	?preferredHeight:Float,
	?fillWidthFactor:Float,
	?fillHeightFactor:Float
}

@:allow(s.ui.Element)
class LayoutAttribute extends s.shortcut.AttachedAttribute<Element> {
	public static inline function setAttributes(x:LayoutAttribute, a:LayoutAttributeAttributes) {
		if (a.row != null)
			x.row = a.row ?? x.row;
		if (a.rowSpan != null)
			x.rowSpan = a.rowSpan ?? x.rowSpan;
		if (a.column != null)
			x.column = a.column ?? x.column;
		if (a.columnSpan != null)
			x.columnSpan = a.columnSpan ?? x.columnSpan;
		if (a.weight != null)
			x.weight = a.weight ?? x.weight;
		if (a.alignment != null)
			x.alignment = a.alignment ?? x.alignment;
		if (a.fillWidth != null)
			x.fillWidth = a.fillWidth ?? x.fillWidth;
		if (a.fillHeight != null)
			x.fillHeight = a.fillHeight ?? x.fillHeight;
		if (a.minimumWidth != null)
			x.minimumWidth = a.minimumWidth ?? x.minimumWidth;
		if (a.maximumWidth != null)
			x.maximumWidth = a.maximumWidth ?? x.maximumWidth;
		if (a.minimumHeight != null)
			x.minimumHeight = a.minimumHeight ?? x.minimumHeight;
		if (a.maximumHeight != null)
			x.maximumHeight = a.maximumHeight ?? x.maximumHeight;
		if (a.preferredWidth != null)
			x.preferredWidth = a.preferredWidth ?? x.preferredWidth;
		if (a.preferredHeight != null)
			x.preferredHeight = a.preferredHeight ?? x.preferredHeight;
		if (a.fillWidthFactor != null)
			x.fillWidthFactor = a.fillWidthFactor ?? x.fillWidthFactor;
		if (a.fillHeightFactor != null)
			x.fillHeightFactor = a.fillHeightFactor ?? x.fillHeightFactor;
	}

	@:attr(grid) @:clamp(0) public var row(default, set):Int = 0;
	@:attr(grid) @:clamp(1) public var rowSpan(default, set):Int = 1;
	@:attr(grid) @:clamp(0) public var column(default, set):Int = 0;
	@:attr(grid) @:clamp(1) public var columnSpan(default, set):Int = 1;
	@:attr(distribution) public var weight:Float = 1.0;

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
}
