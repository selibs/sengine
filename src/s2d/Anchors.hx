package s2d;

@:allow(s2d.Element)
class Anchors implements s.shortcut.Shortcut {
	public var left:HorizontalAnchor = null;
	public var hCenter:HorizontalAnchor = null;
	public var right:HorizontalAnchor = null;
	public var top:VerticalAnchor = null;
	public var vCenter:VerticalAnchor = null;
	public var bottom:VerticalAnchor = null;

	public function new() {}

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
		fill(element.left, element.right, element.top, element.bottom);
	}

	overload extern public inline function fill(element:Element) {
		fill(element.left, element.right, element.top, element.bottom);
	}

	overload extern public inline function fillWidth(left:HorizontalAnchor, right:HorizontalAnchor) {
		this.left = left;
		this.right = right;
	}

	overload extern public inline function fillWidth(element:{
		left:HorizontalAnchor,
		right:HorizontalAnchor
	}) {
		fillWidth(element.left, element.right);
	}

	overload extern public inline function fillWidth(element:Element) {
		fillWidth(element.left, element.right);
	}

	overload extern public inline function fillHeight(top:VerticalAnchor, bottom:VerticalAnchor) {
		this.top = top;
		this.bottom = bottom;
	}

	overload extern public inline function fillHeight(element:{
		top:VerticalAnchor,
		bottom:VerticalAnchor
	}) {
		fillHeight(element.top, element.bottom);
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

	overload extern public inline function centerIn(element:{
		hCenter:HorizontalAnchor,
		vCenter:VerticalAnchor
	}) {
		centerIn(element.hCenter, element.vCenter);
	}

	overload extern public inline function centerIn(element:Element) {
		centerIn(element.hCenter, element.vCenter);
	}
}

class HorizontalAnchor extends Anchor {}
class VerticalAnchor extends Anchor {}

@:allow(s2d.Element)
abstract class Anchor implements s.shortcut.Shortcut {
	@:attr var position:Float = 0.0;

	@:attr public var padding:Float = 0.0;
	@:attr public var margin:Float = 0.0;

	public function new() {}

	public function toString():String {
		return Std.string(position);
	}
}
