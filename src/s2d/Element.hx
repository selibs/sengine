package s2d;

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

	@:attr.group public var anchors(default, never) = new Anchors();
	public var padding(never, set):Float;
	public var margins(never, set):Float;

	@:attr.group public var left(default, never) = new HorizontalAnchor();
	@:attr.group public var hCenter(default, never) = new HorizontalAnchor();
	@:attr.group public var right(default, never) = new HorizontalAnchor();
	@:attr.group public var top(default, never) = new VerticalAnchor();
	@:attr.group public var vCenter(default, never) = new VerticalAnchor();
	@:attr.group public var bottom(default, never) = new VerticalAnchor();

	@:attr public var x(default, set):Float = 0.0;
	@:attr public var y(default, set):Float = 0.0;
	@:attr public var width(default, set):Float = 0.0;
	@:attr public var height(default, set):Float = 0.0;

	public var clip:Bool = false; // TODO: stencil test
	@:attr public var opacity:Float = 1.0;
	@:attr public var visible:Bool = true;
	@:attr.group public var layout(default, never):Layout = new Layout();

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
		flush();
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		for (c in children)
			Element.renderElement(target, c);
		ctx.style.popOpacity();
	}

	// anchors
	// TODO: cache anchors
	@:slot(anchors.leftDirty) function flushLeftAnchor(a)
		flushAnchor(a, anchors.left, syncLeftAnchor);

	@:slot(anchors.hCenterDirty) function flushHCenterAnchor(a)
		flushAnchor(a, anchors.hCenter, syncHCenterAnchor);

	@:slot(anchors.rightDirty) function flushRightAnchor(a)
		flushAnchor(a, anchors.right, syncRightAnchor);

	@:slot(anchors.topDirty) function flushTopAnchor(a)
		flushAnchor(a, anchors.top, syncTopAnchor);

	@:slot(anchors.vCenterDirty) function flushVCenterAnchor(a)
		flushAnchor(a, anchors.vCenter, syncVCenterAnchor);

	@:slot(anchors.bottomDirty) function flushBottomAnchor(a)
		flushAnchor(a, anchors.bottom, syncBottomAnchor);

	function flushAnchor(a1:Anchor, a2:Anchor, slot:Float->Void):Void {
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

	@:slot(left.marginDirty) function syncLeftAnchor(_) {
		var a = anchors.left;
		if (a != null)
			left.position = a.position + a.padding + left.margin;
	}

	@:slot(hCenter.marginDirty) function syncHCenterAnchor(_) {
		var a = anchors.hCenter;
		if (a != null)
			hCenter.position = a.position + a.padding + hCenter.margin;
	}

	@:slot(right.marginDirty) function syncRightAnchor(_) {
		var a = anchors.right;
		if (a != null)
			right.position = a.position - a.padding - right.margin;
	}

	@:slot(top.marginDirty) function syncTopAnchor(_) {
		var a = anchors.top;
		if (a != null)
			top.position = a.position + a.padding + top.margin;
	}

	@:slot(vCenter.marginDirty) function syncVCenterAnchor(_) {
		var a = anchors.vCenter;
		if (a != null)
			vCenter.position = a.position + a.padding + vCenter.margin;
	}

	@:slot(bottom.marginDirty) function syncBottomAnchor(_) {
		var a = anchors.bottom;
		if (a != null)
			bottom.position = a.position - a.padding - bottom.margin;
	}

	// geometry

	function syncX() {
		@:bypassAccessor x = left.position;
		if (parent != null)
			@:bypassAccessor x -= parent.left.position;
	}

	function syncY() {
		@:bypassAccessor y = top.position;
		if (parent != null)
			@:bypassAccessor y -= parent.top.position;
	}

	function syncWidth() {
		@:bypassAccessor width = right.position - left.position;
	}

	function syncHeight() {
		@:bypassAccessor height = bottom.position - top.position;
	}

	@:slot(xDirty) function flushX(x:Float) {
		if (anchors.left != null && anchors.hCenter != null || anchors.left != null && anchors.right != null || anchors.hCenter != null
			&& anchors.right != null)
			return;

		left.position = x;
		if (parent != null)
			left.position += parent.left.position;

		if (anchors.left == null && anchors.hCenter == null && anchors.right == null) {
			hCenter.position = left.position + width * 0.5;
			right.position = left.position + width;
		} else if (anchors.left == null && anchors.hCenter != null && anchors.right == null) {
			right.position = hCenter.position + (hCenter.position - left.position);
			syncWidth();
		} else if (anchors.left == null && anchors.hCenter == null && anchors.right != null) {
			syncWidth();
			hCenter.position = left.position + width * 0.5;
		}
	}

	@:slot(yDirty) function flushY(y:Float) {
		if (anchors.top != null && anchors.vCenter != null || anchors.top != null && anchors.bottom != null || anchors.vCenter != null
			&& anchors.bottom != null)
			return;

		top.position = y;
		if (parent != null)
			top.position += parent.top.position;

		if (anchors.top == null && anchors.vCenter == null && anchors.bottom == null) {
			vCenter.position = top.position + height * 0.5;
			bottom.position = top.position + height;
		} else if (anchors.top == null && anchors.vCenter != null && anchors.bottom == null) {
			bottom.position = vCenter.position + (vCenter.position - top.position);
			syncHeight();
		} else if (anchors.top == null && anchors.vCenter == null && anchors.bottom != null) {
			syncHeight();
			vCenter.position = top.position + height * 0.5;
		}
	}

	@:slot(widthDirty) function flushWidth(width:Float) {
		if (anchors.hCenter == null && anchors.right == null) {
			right.position = left.position + width;
			hCenter.position = left.position + width * 0.5;
		} else {
			if (anchors.left == null && anchors.hCenter == null && anchors.right != null) {
				left.position = right.position - width;
				hCenter.position = right.position - width * 0.5;
			} else if (anchors.left == null && anchors.hCenter != null && anchors.right == null) {
				var d = width * 0.5;
				left.position = hCenter.position - d;
				right.position = hCenter.position + d;
			} else
				return;
			syncX();
		}
	}

	@:slot(heightDirty) function flushHeight(height:Float) {
		if (anchors.vCenter == null && anchors.bottom == null) {
			bottom.position = top.position + height;
			vCenter.position = top.position + height * 0.5;
		} else {
			if (anchors.top == null && anchors.vCenter == null && anchors.bottom != null) {
				top.position = bottom.position - height;
				vCenter.position = bottom.position - height * 0.5;
			} else if (anchors.top == null && anchors.vCenter != null && anchors.bottom == null) {
				var d = height * 0.5;
				top.position = vCenter.position - d;
				bottom.position = vCenter.position + d;
			} else
				return;
			syncY();
		}
	}

	@:slot(left.positionDirty) function flushLeftPosition(p) {
		syncX();
		if (anchors.right == null && anchors.hCenter == null) {
			right.position = left.position + width;
			hCenter.position = (left.position + right.position) * 0.5;
		} else {
			if (anchors.right != null && anchors.hCenter == null)
				hCenter.position = (left.position + right.position) * 0.5;
			else if (anchors.right == null && anchors.hCenter != null)
				right.position = hCenter.position + (hCenter.position - left.position);
			syncWidth();
		}
	}

	@:slot(hCenter.positionDirty) function flushHCenterPosition(p) {
		if (anchors.left == null && anchors.right == null) {
			var d = width * 0.5;
			left.position = hCenter.position - d;
			right.position = hCenter.position + d;
			syncX();
		} else {
			if (anchors.left != null && anchors.right == null)
				right.position = hCenter.position + (hCenter.position - left.position);
			else if (anchors.left == null && anchors.right != null) {
				left.position = hCenter.position - (right.position - hCenter.position);
				syncX();
			}
			syncWidth();
		}
	}

	@:slot(right.positionDirty) function flushRightPosition(p) {
		if (anchors.left == null && anchors.hCenter == null) {
			left.position = right.position - width;
			hCenter.position = (left.position + right.position) * 0.5;
			syncX();
		} else {
			if (anchors.left != null && anchors.hCenter == null)
				hCenter.position = (left.position + right.position) * 0.5;
			else if (anchors.left == null && anchors.hCenter != null) {
				left.position = hCenter.position - (right.position - hCenter.position);
				syncX();
			}
			syncWidth();
		}
	}

	@:slot(top.positionDirty) function flushTopPosition(p) {
		syncY();
		if (anchors.bottom == null && anchors.vCenter == null) {
			bottom.position = top.position + height;
			vCenter.position = (top.position + bottom.position) * 0.5;
		} else {
			if (anchors.bottom != null && anchors.vCenter == null)
				vCenter.position = (top.position + bottom.position) * 0.5;
			else if (anchors.bottom == null && anchors.vCenter != null)
				bottom.position = vCenter.position + (vCenter.position - top.position);
			syncHeight();
		}
	}

	@:slot(vCenter.positionDirty) function flushVCenterPosition(p) {
		if (anchors.top == null && anchors.bottom == null) {
			var d = height * 0.5;
			top.position = vCenter.position - d;
			bottom.position = vCenter.position + d;
			syncY();
		} else {
			if (anchors.top != null && anchors.bottom == null)
				bottom.position = vCenter.position + (vCenter.position - top.position);
			else if (anchors.top == null && anchors.bottom != null) {
				top.position = vCenter.position - (bottom.position - vCenter.position);
				syncY();
			}
			syncHeight();
		}
	}

	@:slot(bottom.positionDirty) function flushBottomPosition(p) {
		if (anchors.top == null && anchors.vCenter == null) {
			top.position = bottom.position - height;
			vCenter.position = (top.position + bottom.position) * 0.5;
			syncY();
		} else {
			if (anchors.top != null && anchors.vCenter == null)
				vCenter.position = (top.position + bottom.position) * 0.5;
			else if (anchors.top == null && anchors.vCenter != null) {
				top.position = vCenter.position - (bottom.position - vCenter.position);
				syncY();
			}
			syncHeight();
		}
	}

	function set_x(value:Float):Float {
		if (!left.positionIsDirty)
			x = value;
		return x;
	}

	function set_y(value:Float):Float {
		if (!top.positionIsDirty)
			y = value;
		return y;
	}

	function set_width(value:Float):Float {
		var c = 0;
		if (left.positionIsDirty)
			c++;
		if (hCenter.positionIsDirty)
			c++;
		if (right.positionIsDirty)
			c++;
		if (c <= 1)
			width = value;
		return width;
	}

	function set_height(value:Float):Float {
		var c = 0;
		if (top.positionIsDirty)
			c++;
		if (vCenter.positionIsDirty)
			c++;
		if (bottom.positionIsDirty)
			c++;
		if (c <= 1)
			height = value;
		return height;
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
