package s.ui;

import s.ui.AnchorLineAttribute;
import s.ui.Element;

@:allow(s.ui.Element)
class AnchorsAttribute extends s.shortcut.AttachedAttribute<Element> {
	@:attr(horizontal) public var left:HorizontalAnchor = null;
	@:attr(horizontal) public var hCenter:HorizontalAnchor = null;
	@:attr(horizontal) public var right:HorizontalAnchor = null;
	@:attr(vertical) public var top:VerticalAnchor = null;
	@:attr(vertical) public var vCenter:VerticalAnchor = null;
	@:attr(vertical) public var bottom:VerticalAnchor = null;

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
	})
		fill(element.left, element.right, element.top, element.bottom);

	overload extern public inline function fill(element:Element)
		fill(element.left, element.right, element.top, element.bottom);

	overload extern public inline function fillWidth(left:HorizontalAnchor, right:HorizontalAnchor) {
		this.left = left;
		this.right = right;
	}

	overload extern public inline function fillWidth(element:{
		left:HorizontalAnchor,
		right:HorizontalAnchor
	})
		fillWidth(element.left, element.right);

	overload extern public inline function fillWidth(element:Element)
		fillWidth(element.left, element.right);

	overload extern public inline function fillHeight(top:VerticalAnchor, bottom:VerticalAnchor) {
		this.top = top;
		this.bottom = bottom;
	}

	overload extern public inline function fillHeight(element:{
		top:VerticalAnchor,
		bottom:VerticalAnchor
	})
		fillHeight(element.top, element.bottom);

	overload extern public inline function fillHeight(element:Element)
		fillHeight(element.top, element.bottom);

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
	})
		centerIn(element.hCenter, element.vCenter);

	overload extern public inline function centerIn(element:Element)
		centerIn(element.hCenter, element.vCenter);

	function set_left(value:HorizontalAnchor):HorizontalAnchor {
		if (left == value)
			return left;
		if (left != null)
			left.removeDependent(object);
		left = value;
		if (left != null)
			left.addDependent(object);
		return left;
	}

	function set_hCenter(value:HorizontalAnchor):HorizontalAnchor {
		if (hCenter == value)
			return hCenter;
		if (hCenter != null)
			hCenter.removeDependent(object);
		hCenter = value;
		if (hCenter != null)
			hCenter.addDependent(object);
		return hCenter;
	}

	function set_right(value:HorizontalAnchor):HorizontalAnchor {
		if (right == value)
			return right;
		if (right != null)
			right.removeDependent(object);
		right = value;
		if (right != null)
			right.addDependent(object);
		return right;
	}

	function set_top(value:VerticalAnchor):VerticalAnchor {
		if (top == value)
			return top;
		if (top != null)
			top.removeDependent(object);
		top = value;
		if (top != null)
			top.addDependent(object);
		return top;
	}

	function set_vCenter(value:VerticalAnchor):VerticalAnchor {
		if (vCenter == value)
			return vCenter;
		if (vCenter != null)
			vCenter.removeDependent(object);
		vCenter = value;
		if (vCenter != null)
			vCenter.addDependent(object);
		return vCenter;
	}

	function set_bottom(value:VerticalAnchor):VerticalAnchor {
		if (bottom == value)
			return bottom;
		if (bottom != null)
			bottom.removeDependent(object);
		bottom = value;
		if (bottom != null)
			bottom.addDependent(object);
		return bottom;
	}
}
