package s2d;

import s2d.Alignment;
import s2d.Element;

#if !macro
@:build(s.shortcut.Macro.build())
#end
class Layout {
	public static function clampWidth(el:Element, width:Float) {
		final l = el.layout;
		return Math.max(l.minimumWidth, Math.min(width, l.maximumWidth)) + el.left.margin + el.right.margin;
	}

	public static function clampHeight(el:Element, height:Float) {
		final l = el.layout;
		return Math.max(l.minimumHeight, Math.min(height, l.maximumHeight)) + el.top.margin + el.bottom.margin;
	}

	@:signal @:isVar public var row(default, set):Int = 0;
	@:signal @:isVar public var rowSpan(default, set):Int = 1;
	@:signal @:isVar public var column(default, set):Int = 0;
	@:signal @:isVar public var columnSpan(default, set):Int = 1;
	@:signal public var alignment:Alignment = AlignCenter;
	@:signal public var weight:Float = 1.0;
	@:signal public var fillWidth:Bool = false;
	@:signal public var fillHeight:Bool = false;
	@:signal public var minimumWidth:Float = 0.0;
	@:signal public var maximumWidth:Float = Math.POSITIVE_INFINITY;
	@:signal public var minimumHeight:Float = 0.0;
	@:signal public var maximumHeight:Float = Math.POSITIVE_INFINITY;
	@:signal public var preferredWidth:Float = Math.NaN;
	@:signal public var preferredHeight:Float = Math.NaN;

	public function new() {}

	function set_row(value:Int):Int {
		row = value < 0 ? 0 : value;
		return row;
	}

	function set_rowSpan(value:Int):Int {
		rowSpan = value < 1 ? 1 : value;
		return rowSpan;
	}

	function set_column(value:Int):Int {
		column = value < 0 ? 0 : value;
		return column;
	}

	function set_columnSpan(value:Int):Int {
		columnSpan = value < 1 ? 1 : value;
		return columnSpan;
	}
}
