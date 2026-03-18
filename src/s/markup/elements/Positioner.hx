package s.markup.elements;

import s.markup.Direction;

using s.system.extensions.ArrayExt;

@:privateAccess
class Positioner extends Element {
	var slots:Map<Element, {
		widthDirty:Float->Void,
		leftMarginDirty:Float->Void,
		rightMarginDirty:Float->Void,
		heightDirty:Float->Void,
		topMarginDirty:Float->Void,
		bottomMarginDirty:Float->Void
	}> = [];

	public var spacing(default, set):Float = 10.0;
	public var direction(default, set):Direction = TopToBottom | LeftToRight;
	public var axis(default, set):Axis;

	public function new(axis:Axis = Horizontal) {
		super();
		this.axis = axis;
	}

	override function __childAdded__(child:Element) {
		slots.set(child, {
			widthDirty: (w:Float) -> adjustElementH(child, RightToLeft, w - child.width),
			leftMarginDirty: (m:Float) -> adjustElementH(child, LeftToRight, child.left.margin - m),
			rightMarginDirty: (m:Float) -> adjustElementH(child, RightToLeft, m - child.right.margin),
			heightDirty: (w:Float) -> adjustElementV(child, BottomToTop, w - child.height),
			topMarginDirty: (m:Float) -> adjustElementV(child, TopToBottom, child.top.margin - m),
			bottomMarginDirty: (m:Float) -> adjustElementV(child, BottomToTop, m - child.bottom.margin)
		});
		super.__childAdded__(child);
	}

	override function __childRemoved__(child:Element) {
		super.__childRemoved__(child);
		slots.remove(child);
	}

	override function sync() {
		super.sync();

		if (axis == Horizontal) {
			if (direction & LeftToRight != 0) {
				if (left.positionIsDirty || left.paddingIsDirty) {
					var p = left.position + left.padding;
					for (c in children) {
						c.left.position = p + c.left.margin;
						p = c.right.position + c.right.padding;
					}
				} else {}
			} else if (direction & RightToLeft != 0) {
				if (right.positionIsDirty || right.paddingIsDirty) {
					var p = right.position - right.padding;
					for (c in children) {
						c.right.position = p - c.right.margin;
						p = c.left.position - c.left.padding;
					}
				} else {}
			}
		} else {
			if (direction & TopToBottom != 0) {
				if (top.positionIsDirty || top.paddingIsDirty) {
					var p = top.position + top.padding;
					for (c in children) {
						c.top.position = p + c.top.margin;
						p = c.bottom.position + c.bottom.padding;
					}
				} else {}
			} else if (direction & RightToLeft != 0) {
				if (bottom.positionIsDirty || bottom.paddingIsDirty) {
					var p = bottom.position - bottom.padding;
					for (c in children) {
						c.bottom.position = p - c.bottom.margin;
						p = c.top.position - c.top.padding;
					}
				} else {}
			}
		}
	}

	@:slot(childAdded)
	function trackElement(el:Element) {
		rebuild();
		if (axis == Vertical)
			trackElementV(el);
		else
			trackElementH(el);
	}

	@:slot(childRemoved)
	function untrackElement(el:Element) {
		if (axis == Vertical)
			untrackElementV(el);
		else
			untrackElementH(el);
	}

	function trackElementH(el:Element) {
		var childSlots = slots.get(el);
		el.onWidthDirty(childSlots.widthDirty);
		el.left.onMarginDirty(childSlots.leftMarginDirty);
		el.right.onMarginDirty(childSlots.rightMarginDirty);
	}

	function trackElementV(el:Element) {
		var childSlots = slots.get(el);
		el.onHeightDirty(childSlots.heightDirty);
		el.top.onMarginDirty(childSlots.topMarginDirty);
		el.bottom.onMarginDirty(childSlots.bottomMarginDirty);
	}

	function untrackElementH(el:Element) {
		var childSlots = slots.get(el);
		el.offWidthDirty(childSlots.widthDirty);
		el.left.offMarginDirty(childSlots.leftMarginDirty);
		el.right.offMarginDirty(childSlots.rightMarginDirty);
	}

	function untrackElementV(el:Element) {
		var childSlots = slots.get(el);
		el.offWidthDirty(childSlots.widthDirty);
		el.left.offMarginDirty(childSlots.leftMarginDirty);
		el.right.offMarginDirty(childSlots.rightMarginDirty);
	}

	function syncWidth(v:Float) {
		super.syncWidth();
		adjustH(RightToLeft, width - v);
	}

	function syncLeftPadding(v:Float) {
		adjustH(LeftToRight, left.padding - v);
	}

	function syncRightPadding(v:Float) {
		adjustH(RightToLeft, v - right.padding);
	}

	function syncHeight(v:Float) {
		adjustV(BottomToTop, height - v);
	}

	function syncTopPadding(v:Float) {
		adjustV(TopToBottom, top.padding - v);
	}

	function syncBottomPadding(v:Float) {
		adjustV(BottomToTop, v - bottom.padding);
	}

	function positionH(el:Element, prev:Element) {
		if (prev == null) {
			if (direction & RightToLeft != 0)
				el.x = width - (el.width + el.right.margin + right.padding);
			else
				el.x = el.left.margin;
		} else {
			if (direction & RightToLeft != 0)
				el.x = prev.x - (prev.left.margin + spacing + el.right.margin + el.width);
			else
				el.x = prev.x + prev.width + prev.right.margin + spacing + el.left.margin;
		}
	}

	function positionV(el:Element, prev:Element) {
		if (prev == null) {
			if (direction & BottomToTop != 0)
				el.y = height - (el.height + el.bottom.margin + bottom.padding);
			else
				el.y = el.top.margin;
		} else {
			if (direction & BottomToTop != 0)
				el.y = prev.y - (prev.top.margin + spacing + el.bottom.margin + el.height);
			else
				el.y = prev.y + prev.height + prev.bottom.margin + spacing + el.top.margin;
		}
	}

	function adjustH(dir:Direction, d:Float) {
		if (direction & dir != 0)
			for (c in children)
				c.x += d;
	}

	function adjustV(dir:Direction, d:Float) {
		if (direction & dir != 0)
			for (c in children)
				c.y += d;
	}

	function adjustElementH(el:Element, dir:Alignment, d:Float) {
		if (direction & dir != 0)
			for (i in children.indexOf(el)...children.length)
				children[i].x += d;
		else
			for (i in (children.indexOf(el) + 1)...children.length)
				children[i].x -= d;
	}

	function adjustElementV(el:Element, dir:Alignment, d:Float) {
		if (direction & dir != 0)
			for (i in children.indexOf(el)...children.length)
				children[i].y += d;
		else
			for (i in (children.indexOf(el) + 1)...children.length)
				children[i].y -= d;
	}

	function rebuild() {
		if (axis == Vertical)
			rebuildV();
		else
			rebuildH();
	}

	function rebuildH() {
		if (children.length > 0)
			for (i in 0...children.length)
				positionH(children[i], children[i - 1]);
	}

	function rebuildV() {
		if (children.length > 0)
			for (i in 0...children.length)
				positionV(children[i], children[i - 1]);
	}

	function set_spacing(value:Float):Float {
		var d = value - spacing;
		spacing = value;

		var offset = 0.0;
		if (axis == Vertical) {
			if (direction & BottomToTop != 0)
				d = -d;
			for (c in children) {
				c.y += offset;
				offset += d;
			}
		} else {
			if (direction & RightToLeft != 0)
				d = -d;
			for (c in children) {
				c.x += offset;
				offset += d;
			}
		}
		return spacing;
	}

	function set_direction(value:Direction):Direction {
		direction = value;
		rebuild();
		return direction;
	}

	function set_axis(value:Axis) {
		axis = value;
		if (axis == Vertical) {
			for (c in children) {
				untrackElementH(c);
				trackElementV(c);
			}
			offWidthDirty(syncWidth);
			left.offPaddingDirty(syncLeftPadding);
			right.offPaddingDirty(syncRightPadding);
			onHeightDirty(syncHeight);
			top.onPaddingDirty(syncTopPadding);
			bottom.onPaddingDirty(syncBottomPadding);
		} else {
			for (c in children) {
				untrackElementV(c);
				trackElementH(c);
			}
			offHeightDirty(syncHeight);
			top.offPaddingDirty(syncTopPadding);
			bottom.offPaddingDirty(syncBottomPadding);
			onWidthDirty(syncWidth);
			left.onPaddingDirty(syncLeftPadding);
			right.onPaddingDirty(syncRightPadding);
		}
		rebuild();
		return axis;
	}
}

enum Axis {
	Horizontal;
	Vertical;
}
