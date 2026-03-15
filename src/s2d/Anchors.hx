package s2d;

import se.Log;
import s2d.Element;

class ElementAnchors {
	var el:Element;

	public var left(get, set):HorizontalAnchor;
	public var hCenter(get, set):HorizontalAnchor;
	public var right(get, set):HorizontalAnchor;
	public var top(get, set):VerticalAnchor;
	public var vCenter(get, set):VerticalAnchor;
	public var bottom(get, set):VerticalAnchor;

	public var margins(never, set):Float;

	public function new(el:Element) {
		this.el = el;
	}

	public function clear() {
		clearH();
		clearV();
	}

	public function clearH() {
		unfillWidth();
		hCenter = null;
	}

	public function clearV() {
		unfillHeight();
		vCenter = null;
	}

	overload extern public inline function fill(left:HorizontalAnchor, right:HorizontalAnchor, top:VerticalAnchor, bottom:VerticalAnchor) {
		fillWidth(left, right);
		fillHeight(top, bottom);
	}

	overload extern public inline function fill(element:{
		left:HorizontalAnchor,
		right:HorizontalAnchor,
		top:VerticalAnchor,
		bottom:VerticalAnchor
	}) {
		if (element != null)
			fill(element.left, element.right, element.top, element.bottom);
	}

	overload extern public inline function fill(element:Element) {
		if (element != null)
			fill(element.left, element.right, element.top, element.bottom);
	}

	overload extern public inline function fillWidth(left:HorizontalAnchor, right:HorizontalAnchor) {
		this.left = left;
		this.right = right;
	}

	overload extern public inline function fillWidth(element:Element) {
		fillWidth(element.left, element.right);
	}

	overload extern public inline function fillHeight(top:VerticalAnchor, bottom:VerticalAnchor) {
		this.top = top;
		this.bottom = bottom;
	}

	overload extern public inline function fillHeight(element:Element) {
		fillHeight(element.top, element.bottom);
	}

	overload extern public inline function unfill() {
		unfillWidth();
		unfillHeight();
	}

	overload extern public inline function unfillWidth() {
		left = null;
		right = null;
	}

	overload extern public inline function unfillHeight() {
		top = null;
		bottom = null;
	}

	overload extern public inline function centerIn(hCenter:HorizontalAnchor, vCenter:VerticalAnchor) {
		this.hCenter = hCenter;
		this.vCenter = vCenter;
	}

	overload extern public inline function centerIn(element:Element) {
		centerIn(element.hCenter, element.vCenter);
	}

	overload extern public inline function setMargins(left:Float, top:Float, right:Float, bottom:Float):Void {
		el.left.margin = left;
		el.top.margin = top;
		el.right.margin = right;
		el.bottom.margin = bottom;
	}

	overload extern public inline function setMargins(value:Float):Void {
		setMargins(value, value, value, value);
	}

	function bindH(ela:HorizontalAnchor, a:HorizontalAnchor) @:privateAccess {
		final el_x = el.x;
		final el_width = el.width;
		ela.bindTo(a);
		if (el.anchoring != 0) {
			el.anchoring = 0;
			ela.unbindFrom();
			el.x = el_x;
			el.width = el_width;
		}
	}

	function bindV(ea:VerticalAnchor, a:VerticalAnchor) @:privateAccess {
		final el_y = el.y;
		final el_height = el.height;
		ea.bindTo(a);
		if (el.anchoring != 0) {
			el.anchoring = 0;
			ea.unbindFrom();
			el.y = el_y;
			el.height = el_height;
		}
	}

	function set_margins(value:Float) {
		setMargins(value);
		return value;
	}

	function get_left() {
		return el.left.bindedTo;
	}

	function set_left(value) {
		bindH(el.left, value);
		return left;
	}

	function get_hCenter() {
		return el.hCenter.bindedTo;
	}

	function set_hCenter(value) {
		bindH(el.hCenter, value);
		return hCenter;
	}

	function get_right() {
		return el.right.bindedTo;
	}

	function set_right(value) {
		bindH(el.right, value);
		return right;
	}

	function get_top() {
		return el.top.bindedTo;
	}

	function set_top(value) {
		bindV(el.top, value);
		return top;
	}

	function get_vCenter() {
		return el.vCenter.bindedTo;
	}

	function set_vCenter(value) {
		bindV(el.vCenter, value);
		return vCenter;
	}

	function get_bottom() {
		return el.bottom.bindedTo;
	}

	function set_bottom(value) {
		bindV(el.bottom, value);
		return bottom;
	}
}

abstract class Anchor<A:Anchor<A>> implements s.shortcut.Shortcut {
	var bindedLines:Array<A> = [];
	var updating:Bool = false;
	var _position:Float = 0.0;

	public var bindedTo(default, set):A = null;
	public var isBinded(get, never):Bool;

	public var position(get, set):Float;
	public var padding(default, set):Float = 0.0;
	public var margin(default, set):Float = 0.0;

	@:signal public function positionChanged(position:Float):Void;

	@:signal public function paddingChanged(padding:Float):Void;

	@:signal public function marginChanged(margin:Float):Void;

	public function new(?position:Float) {
		if (position != null)
			this.position = position;
	}

	public function bind(line:A) {
		line.bindTo(cast this);
	}

	public function unbind(line:A) {
		if (bindedLines.contains(line))
			line.unbindFrom();
	}

	public function bindTo(line:A) {
		bindedTo = line;
	}

	public function unbindFrom() {
		bindedTo = null;
	}

	public function hasLoop(anchor:A):Bool {
		var a = anchor;
		while (a != null) {
			if (anchor == this)
				return true;
			a = a.bindedTo;
		}
		return false;
	}

	function update(f:Void->Void) {
		updating = true;
		f();
		updating = false;
	}

	abstract function syncOffset(d:Float):Void;

	function get_isBinded() {
		return bindedTo != null;
	}

	function set_bindedTo(value:A):A {
		if (value != bindedTo)
			if (!hasLoop(value)) {
				var offset = 0.0;
				if (isBinded) {
					bindedTo.bindedLines.remove(cast this);
					offset -= bindedTo.padding + margin;
				}
				if (value != null) {
					value.bindedLines.push(cast this);
					position = value.position;
					offset += value.padding + margin;
				}
				bindedTo = value;
				if (isBinded)
					bindedTo.update(() -> syncOffset(offset));
				else
					syncOffset(offset);
			} else
				Log.warning("Anchor binding loop detected!");
		return bindedTo;
	}

	function get_position():Float {
		return _position;
	}

	function set_position(value:Float):Float {
		if (!isBinded || bindedTo.updating) {
			final prev = position;
			_position = value;
			final d = value - prev;
			update(() -> {
				for (l in bindedLines)
					l.position += d;
			});
			positionChanged(prev);
		}
		return value;
	}

	function set_padding(value:Float):Float {
		final prev = padding;
		padding = value;
		update(() -> {
			final d = padding - prev;
			for (line in bindedLines)
				line.syncOffset(d);
		});
		paddingChanged(prev);
		return padding;
	}

	function set_margin(value:Float):Float {
		final prev = margin;
		margin = value;
		if (isBinded)
			bindedTo.update(() -> syncOffset(margin - prev));
		marginChanged(prev);
		return margin;
	}
}

abstract class HorizontalAnchor extends Anchor<HorizontalAnchor> {}

class LeftAnchor extends HorizontalAnchor {
	function syncOffset(d:Float) {
		position += d;
	}
}

class HCenterAnchor extends HorizontalAnchor {
	function syncOffset(d:Float) {
		position += d;
	}
}

class RightAnchor extends HorizontalAnchor {
	function syncOffset(d:Float) {
		position -= d;
	}
}

abstract class VerticalAnchor extends Anchor<VerticalAnchor> {}

class TopAnchor extends VerticalAnchor {
	function syncOffset(d:Float) {
		position += d;
	}
}

class VCenterAnchor extends VerticalAnchor {
	function syncOffset(d:Float) {
		position += d;
	}
}

class BottomAnchor extends VerticalAnchor {
	function syncOffset(d:Float) {
		position -= d;
	}
}
