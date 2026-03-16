package s2d;

import s2d.Alignment;
import s2d.Element;

class Layout implements s.shortcut.Shortcut {
	public static function clampWidth(el:Element, width:Float) {
		final l = el.layout;
		return Math.max(l.minimumWidth, Math.min(width, l.maximumWidth)) + el.left.margin + el.right.margin;
	}

	public static function clampHeight(el:Element, height:Float) {
		final l = el.layout;
		return Math.max(l.minimumHeight, Math.min(height, l.maximumHeight)) + el.top.margin + el.bottom.margin;
	}

	@:attr public var row(default, set):Int = 0;
	@:attr public var rowSpan(default, set):Int = 1;
	@:attr public var column(default, set):Int = 0;
	@:attr public var columnSpan(default, set):Int = 1;
	@:attr public var alignment:Alignment = AlignCenter;
	@:attr public var weight:Float = 1.0;
	@:attr public var fillWidth:Bool = false;
	@:attr public var fillHeight:Bool = false;
	@:attr public var minimumWidth:Float = 0.0;
	@:attr public var maximumWidth:Float = Math.POSITIVE_INFINITY;
	@:attr public var minimumHeight:Float = 0.0;
	@:attr public var maximumHeight:Float = Math.POSITIVE_INFINITY;
	@:attr public var preferredWidth:Float = Math.NaN;
	@:attr public var preferredHeight:Float = Math.NaN;

	public function new() {}

	inline function set_row(value:Int):Int
		return row = value < 0 ? 0 : value;

	inline function set_rowSpan(value:Int):Int
		return rowSpan = value < 1 ? 1 : value;

	inline function set_column(value:Int):Int
		return column = value < 0 ? 0 : value;

	inline function set_columnSpan(value:Int):Int
		return columnSpan = value < 1 ? 1 : value;
}
