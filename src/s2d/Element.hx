package s2d;

import se.Log;
import se.Texture;
import se.math.SMath;
import s2d.Style;
import s2d.Anchors;
import s2d.geometry.Size;
import s2d.geometry.Position;

@:allow(s2d.WindowScene)
class Element extends Object2D<Element> {
	overload extern public static inline function mapToElement(element:Element, x:Float, y:Float):Position {
		return element.mapFromGlobal(x, y);
	}

	overload extern public static inline function mapToElement(element:Element, p:Position):Position {
		return element.mapFromGlobal(p.x, p.y);
	}

	overload extern public static inline function mapFromElement(element:Element, x:Float, y:Float):Position {
		return element.mapToGlobal(x, y);
	}

	overload extern public static inline function mapFromElement(element:Element, p:Position):Position {
		return element.mapToGlobal(p.x, p.y);
	}

	public static function renderElement(target:Texture, element:Element) {
		if (!element.visible)
			return;
		final ctx = target.context2D;
		ctx.pushTransformation(element.transform);
		element.render(target);
		ctx.popTransformation();
	}

	public var left(default, never) = new HorizontalAnchor();
	public var hCenter(default, never) = new HorizontalAnchor();
	public var right(default, never) = new HorizontalAnchor();
	public var top(default, never) = new VerticalAnchor();
	public var vCenter(default, never) = new VerticalAnchor();
	public var bottom(default, never) = new VerticalAnchor();
	public var anchors(default, never) = new Anchors();
	public var padding(never, set):Float;
	public var margins(never, set):Float;

	public var layout(default, never):Layout = new Layout();

	@:attr public var x:Float = 0.0;
	@:attr public var y:Float = 0.0;
	@:attr public var width:Float = 50.0;
	@:attr public var height:Float = 50.0;

	@:attr public var clip:Bool = false; // TODO: stencil test
	@:attr public var opacity:Float = 1.0;
	@:attr public var visible:Bool = true;

	public function setPadding(value:Float):Void {
		left.padding = value;
		top.padding = value;
		right.padding = value;
		bottom.padding = value;
	}

	public function setMargins(value:Float):Void {
		left.margin = value;
		top.margin = value;
		right.margin = value;
		bottom.margin = value;
	}

	overload extern public inline function setSize(size:Size):Void {
		setSize(size.width, size.height);
	}

	overload extern public inline function setSize(width:Float, height:Float):Void {
		this.width = width;
		this.height = height;
	}

	overload extern public inline function setPosition(position:Position):Void {
		setPosition(position.x, position.y);
	}

	overload extern public inline function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	overload extern public inline function mapFromGlobal(p:Position):Position {
		return transform * p - vec2(left.position, top.position);
	}

	overload extern public inline function mapFromGlobal(x:Float, y:Float):Position {
		return mapFromGlobal(vec2(x, y));
	}

	overload extern public inline function mapToGlobal(p:Position):Position {
		return inverse(transform) * p;
	}

	overload extern public inline function mapToGlobal(x:Float, y:Float):Position {
		return mapToGlobal(vec2(x, y));
	}

	public function childAt(x:Float, y:Float):Element {
		var i = children.length;
		while (0 < i) {
			final c = children[--i];
			if (c.covers(x, y))
				return c;
		}
		return null;
	}

	public function descendantAt(x:Float, y:Float):Element {
		var i = children.length;
		while (0 < i) {
			final c = children[--i];
			var cat = c.descendantAt(x, y);
			if (cat == null) {
				if (c.covers(x, y))
					return c;
			} else
				return cat;
		};
		return null;
	}

	public function covers(x:Float, y:Float):Bool {
		var p = mapToGlobal(x, y);
		return left.position <= p.x && p.x <= right.position && top.position <= p.y && p.y <= bottom.position;
	}

	public function useStylesheet(stylesheet:Stylesheet) {
		for (s in stylesheet)
			useStyle(s);
	}

	public function removeStylesheet(stylesheet:Stylesheet) {
		for (s in stylesheet)
			removeStyle(s);
	}

	public inline function useStyle(style:Style) {
		style.apply(this);
	}

	public inline function removeStyle(style:Style) {
		return style.remove(this);
	}

	function render(target:Texture) {
        left.flush();
        hCenter.flush();
        right.flush();
        top.flush();
        vCenter.flush();
        bottom.flush();

		anchors.flush();
		flush();

		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		for (c in children)
			Element.renderElement(target, c);
		ctx.style.popOpacity();
	}

	// anchors
	// TODO: cache anchors
	@:slot(anchors.leftDirty) function syncLeftAnchor(a)
		syncAnchor(a, anchors.left, syncLeft);

	@:slot(anchors.hCenterDirty) function syncHCenterAnchor(a)
		syncAnchor(a, anchors.hCenter, syncHCenter);

	@:slot(anchors.rightDirty) function syncRightAnchor(a)
		syncAnchor(a, anchors.right, syncRight);

	@:slot(anchors.topDirty) function syncTopAnchor(a)
		syncAnchor(a, anchors.top, syncTop);

	@:slot(anchors.vCenterDirty) function syncVCenterAnchor(a)
		syncAnchor(a, anchors.vCenter, syncVCenter);

	@:slot(anchors.bottomDirty) function syncBottomAnchor(a)
		syncAnchor(a, anchors.bottom, syncBottom);

	function syncAnchor(a1:Anchor, a2:Anchor, slot:Float->Void):Void {
		if (a1 != null) {
			a1.offPositionDirty(slot);
			a1.offPaddingDirty(slot);
		}
		if (a2 != null) {
			slot(a2.position);
			a2.onPositionDirty(slot);
			a2.onPaddingDirty(slot);
		}
	}

	// positions

	@:slot(left.marginDirty) function syncLeft(_) {
		var a = anchors.left;
		if (a != null)
			left.position = a.position + a.padding + left.margin;
	}

	@:slot(hCenter.marginDirty) function syncHCenter(_) {
		var a = anchors.hCenter;
		if (a != null)
			hCenter.position = a.position + a.padding + hCenter.margin;
	}

	@:slot(right.marginDirty) function syncRight(_) {
		var a = anchors.right;
		if (a != null)
			right.position = a.position - a.padding - right.margin;
	}

	@:slot(top.marginDirty) function syncTop(_) {
		var a = anchors.top;
		if (a != null)
			top.position = a.position + a.padding + top.margin;
	}

	@:slot(vCenter.marginDirty) function syncVCenter(_) {
		var a = anchors.vCenter;
		if (a != null)
			vCenter.position = a.position + a.padding + vCenter.margin;
	}

	@:slot(bottom.marginDirty) function syncBottom(_) {
		var a = anchors.bottom;
		if (a != null)
			bottom.position = a.position - a.padding - bottom.margin;
	}

	// geometry

	@:slot(xDirty) function syncX(x:Float) {
		left.position = x;
		if (parent != null)
			left.position += parent.left.position;
	}

	@:slot(yDirty) function syncY(y:Float) {
		top.position = y;
		if (parent != null)
			top.position += parent.top.position;
	}

	@:slot(widthDirty) function syncWidth(width:Float) {
		if (anchors.left == null) {
			if (anchors.right != null && anchors.hCenter == null)
				left.position = right.position - width;
			else if (anchors.right == null && anchors.hCenter != null) {
				final d = width * 0.5;
				left.position = hCenter.position - d;
				right.position = hCenter.position + d;
			}
		} else if (anchors.right == null && anchors.hCenter == null)
			right.position = left.position + width;
	}

	@:slot(heightDirty) function syncHeight(height:Float) {
		if (anchors.top == null) {
			if (anchors.bottom != null && anchors.vCenter == null)
				top.position = bottom.position - height;
			else if (anchors.bottom == null && anchors.vCenter != null) {
				final d = height * 0.5;
				top.position = vCenter.position - d;
				bottom.position = vCenter.position + d;
			}
		} else if (anchors.bottom == null && anchors.vCenter == null)
			bottom.position = top.position + height;
	}

	@:slot(left.positionDirty) function syncLeftPosition(p) {
		x = left.position;
		if (parent != null)
			x -= parent.left.position;

		if (anchors.right == null && anchors.hCenter == null) {
			right.position = left.position + width;
			hCenter.position = (left.position + right.position) * 0.5;
		} else {
			if (anchors.right != null && anchors.hCenter == null)
				hCenter.position = (left.position + right.position) * 0.5;
			else if (anchors.right == null && anchors.hCenter != null)
				right.position = hCenter.position + (hCenter.position - left.position);
			width = right.position - left.position;
		}
	}

	@:slot(hCenter.positionDirty) function syncHCenterPosition(p) {
		if (anchors.left == null && anchors.right == null) {
			var d = width * 0.5;
			left.position = hCenter.position - d;
			right.position = hCenter.position + d;
		} else {
			if (anchors.left != null && anchors.right == null)
				right.position = hCenter.position + (hCenter.position - left.position);
			else if (anchors.left == null && anchors.right != null)
				left.position = hCenter.position - (right.position - hCenter.position);
			width = right.position - left.position;
		}
	}

	@:slot(right.positionDirty) function syncRightPosition(p) {
        trace(right);
		if (anchors.left == null && anchors.hCenter == null) {
			left.position = right.position - width;
			hCenter.position = (left.position + right.position) * 0.5;
		} else {
			if (anchors.left != null && anchors.hCenter == null)
				hCenter.position = (left.position + right.position) * 0.5;
			else if (anchors.left == null && anchors.hCenter != null)
				left.position = hCenter.position - (right.position - hCenter.position);
			width = right.position - left.position;
		}
	}

	@:slot(top.positionDirty) function syncTopPosition(p) {
		y = top.position;
		if (parent != null)
			y -= parent.top.position;

		if (anchors.bottom == null && anchors.vCenter == null) {
			bottom.position = top.position + height;
			vCenter.position = (top.position + bottom.position) * 0.5;
		} else {
			if (anchors.bottom != null && anchors.vCenter == null)
				vCenter.position = (top.position + bottom.position) * 0.5;
			else if (anchors.bottom == null && anchors.vCenter != null)
				bottom.position = vCenter.position + (vCenter.position - top.position);
			height = bottom.position - top.position;
		}
	}

	@:slot(vCenter.positionDirty) function syncVCenterPosition(p) {
		if (anchors.top == null && anchors.bottom == null) {
			var d = height * 0.5;
			top.position = vCenter.position - d;
			bottom.position = vCenter.position + d;
		} else {
			if (anchors.top != null && anchors.bottom == null)
				bottom.position = vCenter.position + (vCenter.position - top.position);
			else if (anchors.top == null && anchors.bottom != null)
				top.position = vCenter.position - (bottom.position - vCenter.position);
			height = bottom.position - top.position;
		}
	}

	@:slot(bottom.positionDirty) function syncBottomPosition(p) {
		if (anchors.top == null && anchors.vCenter == null) {
			top.position = bottom.position - height;
			vCenter.position = (top.position + bottom.position) * 0.5;
		} else {
			if (anchors.top != null && anchors.vCenter == null)
				vCenter.position = (top.position + bottom.position) * 0.5;
			else if (anchors.top == null && anchors.vCenter != null)
				top.position = vCenter.position - (bottom.position - vCenter.position);
			height = bottom.position - top.position;
		}
	}

	function set_padding(value:Float) {
		setPadding(value);
		return value;
	}

	function set_margins(value:Float) {
		setMargins(value);
		return value;
	}
}
