package s.ui;

import s.ui.elements.Element;

@:allow(s.ui.elements.Element)
class Anchors extends AttachedAttribute {
	@:attr public var left:HorizontalAnchor = null;
	@:attr public var hCenter:HorizontalAnchor = null;
	@:attr public var right:HorizontalAnchor = null;
	@:attr public var top:VerticalAnchor = null;
	@:attr public var vCenter:VerticalAnchor = null;
	@:attr public var bottom:VerticalAnchor = null;

	function new(element:Element)
		super(element);

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

typedef HorizontalAnchor = Anchor<HorizontalAnchorLine>;
typedef VerticalAnchor = Anchor<VerticalAnchorLine>;

@:forward()
@:forward.new
@:allow(s.ui.elements.Element)
extern abstract Anchor<T:AnchorLine>(T) to AnchorLine {
	private var self(get, never):T;

	public var position(get, never):Float;

	public inline function toString():String
		return Std.string(position);

	private inline function get_self()
		return this;

	private inline function get_position()
		return this.position;
}

private class HorizontalAnchorLine extends AnchorLine {}
private class VerticalAnchorLine extends AnchorLine {}

@:allow(s.ui.elements.Element)
abstract class AnchorLine extends AttachedAttribute {
	@:attr public var position:Float = 0.0;
	@:attr public var padding:Float = 0.0;
	@:attr public var margin:Float = 0.0;

	function new(element:Element)
		super(element);
}
