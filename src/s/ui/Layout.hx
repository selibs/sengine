package s.ui;

import s.ui.Anchors.VerticalAnchor;
import s.ui.Anchors.HorizontalAnchor;
import s.ui.Anchors.AnchorLine;
import s.ui.Alignment;
import s.ui.elements.Element;

@:allow(s.ui.elements.Element)
class Layout extends AttachedAttribute {
	public static function clampWidth(el:Element, width:Float) {
		final l = el.layout;
		return Math.max(Math.min(width, l.maximumWidth), l.minimumWidth) + el.left.margin + el.right.margin;
	}

	public static function clampHeight(el:Element, height:Float) {
		final l = el.layout;
		return Math.max(Math.min(height, l.maximumHeight), l.minimumHeight) + el.top.margin + el.bottom.margin;
	}

	overload extern public static inline function alignH(el:Element, left:HorizontalAnchor, hCenter:HorizontalAnchor, right:HorizontalAnchor) {
		final l = el.layout;
		if (l.alignment != Alignment.None) {
			final a = el.anchors;
			if (l.alignment & Alignment.AlignRight != 0) {
				a.right = right;
			} else if (l.alignment & Alignment.AlignHCenter != 0)
				a.hCenter = hCenter;
			else
				a.left = left;
		}
	}

	overload extern public static inline function alignH(el1:Element, el2:Element)
		alignH(el1, el2.left, el2.hCenter, el2.right);

	overload extern public static inline function alignV(el:Element, top:VerticalAnchor, vCenter:VerticalAnchor, bottom:VerticalAnchor) {
		final l = el.layout;
		if (l.alignment != Alignment.None) {
			final a = el.anchors;
			if (l.alignment & Alignment.AlignBottom != 0)
				a.bottom = bottom;
			else if (l.alignment & Alignment.AlignVCenter != 0)
				a.vCenter = vCenter;
			else
				a.top = top;
		}
	}

	overload extern public static inline function alignV(el1:Element, el2:Element)
		alignV(el1, el2.top, el2.vCenter, el2.bottom);

	overload extern public static inline function align(el:Element, left:HorizontalAnchor, hCenter:HorizontalAnchor, right:HorizontalAnchor,
			top:VerticalAnchor, vCenter:VerticalAnchor, bottom:VerticalAnchor) {
		final l = el.layout;
		final a = el.anchors;
		a.clear();
		if (l.alignment == Alignment.None)
			return;

		if (l.alignment & Alignment.AlignRight != 0) {
			a.right = right;
		} else if (l.alignment & Alignment.AlignHCenter != 0)
			a.hCenter = hCenter;
		else
			a.left = left;

		if (l.alignment & Alignment.AlignBottom != 0)
			a.bottom = bottom;
		else if (l.alignment & Alignment.AlignVCenter != 0)
			a.vCenter = vCenter;
		else
			a.top = top;
	}

	overload extern public static inline function align(el1:Element, el2:Element)
		align(el1, el2.left, el2.hCenter, el2.right, el2.top, el2.vCenter, el2.bottom);

	@:attr public var alignment:Alignment = None;
	@:attr public var fillWidth:Bool = false;
	@:attr public var fillHeight:Bool = false;
	@:attr public var minimumWidth:Float = 0.0;
	@:attr public var maximumWidth:Float = Math.POSITIVE_INFINITY;
	@:attr public var minimumHeight:Float = 0.0;
	@:attr public var maximumHeight:Float = Math.POSITIVE_INFINITY;
	@:attr public var preferredWidth:Float = Math.NaN;
	@:attr public var preferredHeight:Float = Math.NaN;
	@:attr public var fillWidthFactor(default, set):Float = 1.0;
	@:attr public var fillHeightFactor(default, set):Float = 1.0;

	@:attr public var row(default, set):Int = 0;
	@:attr public var rowSpan(default, set):Int = 1;
	@:attr public var column(default, set):Int = 0;
	@:attr public var columnSpan(default, set):Int = 1;
	@:attr public var weight:Float = 1.0;

	function new(element:Element)
		super(element);

	inline function set_fillWidthFactor(value:Float):Float
		return fillWidthFactor = value < 0 ? 0 : value;

	inline function set_fillHeightFactor(value:Float):Float
		return fillHeightFactor = value < 0 ? 0 : value;

	inline function set_row(value:Int):Int
		return row = value < 0 ? 0 : value;

	inline function set_rowSpan(value:Int):Int
		return rowSpan = value < 1 ? 1 : value;

	inline function set_column(value:Int):Int
		return column = value < 0 ? 0 : value;

	inline function set_columnSpan(value:Int):Int
		return columnSpan = value < 1 ? 1 : value;
}
