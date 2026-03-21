package s.markup;

import s.markup.Alignment;
import s.markup.Element;

@:allow(s.markup.Element)
class Layout implements s.shortcut.Shortcut {
	public static function clampWidth(el:Element, width:Float) {
		final l = el.layout;
		return Math.max(Math.min(width, l.maximumWidth), l.minimumWidth) + el.left.margin + el.right.margin;
	}

	public static function clampHeight(el:Element, height:Float) {
		final l = el.layout;
		return Math.max(Math.min(height, l.maximumHeight), l.minimumHeight) + el.top.margin + el.bottom.margin;
	}

	@:attr public var alignment:Alignment = None;
	@:attr public var minimumWidth:Length = 0.0;
	@:attr public var maximumWidth:Length = Math.POSITIVE_INFINITY;
	@:attr public var minimumHeight:Length = 0.0;
	@:attr public var maximumHeight:Length = Math.POSITIVE_INFINITY;

	@:attr public var row(default, set):Int = 0;
	@:attr public var rowSpan(default, set):Int = 1;
	@:attr public var column(default, set):Int = 0;
	@:attr public var columnSpan(default, set):Int = 1;
	@:attr public var weight:Float = 1.0;

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
