package s.ui.layouts;

import s.ui.Alignment;
import s.ui.Element;

private typedef LinearItem = {
	var child:Element;
	var fillPrimary:Bool;
	var fillCross:Bool;
	var alignment:Alignment;
	var stretchPrimary:Float;
	var lead:Float;
	var trail:Float;
	var crossLead:Float;
	var crossTrail:Float;
	var prefPrimary:Float;
	var minPrimary:Float;
	var maxPrimary:Float;
	var prefCross:Float;
	var minCross:Float;
	var maxCross:Float;
	var cellMin:Float;
	var cellPref:Float;
	var cellMax:Float;
	var cellSize:Float;
}

class Layout extends Element {
	@:attr var spaceH:Float = 0.0;
	@:attr var spaceV:Float = 0.0;

	@:attr public var spacing:Float = 5.0;

	@:readonly @:alias public var freeWidth:Float = spaceH;
	@:readonly @:alias public var freeHeight:Float = spaceV;

	override function update() {
		super.update();

		if (widthDirty || left.paddingDirty || right.paddingDirty)
			spaceH = width - left.padding - right.padding;
		if (heightDirty || top.paddingDirty || bottom.paddingDirty)
			spaceV = height - top.padding - bottom.padding;
	}

	override function updateChild(c:Element) {
		if (!isChildDirty(c))
			return;
		layoutChild(c);
		super.updateChild(c);
	}

	function commitChild(c:Element) {
		if (c.parentDirty)
			insertChild(c);
		if (c.parentDirty || sceneDirty)
			setChildScene(c);
		if (c.parentDirty || layerDirty)
			setChildLayer(c);

		c.updateTree();
	}

	function layoutChild(c:Element) {
		commitChild(c);

		final l = c.layout;
		final alignment = resolveAlignment(l.alignment, AlignLeft, AlignTop, false);

		final targetWidth = l.fillWidth ? boundedWidth(c, Math.max(0.0, freeWidth - c.left.margin - c.right.margin)) : preferredWidth(c);
		final targetHeight = l.fillHeight ? boundedHeight(c, Math.max(0.0, freeHeight - c.top.margin - c.bottom.margin)) : preferredHeight(c);

		c.width = targetWidth;
		c.height = targetHeight;

		var extraH = freeWidth - c.left.margin - c.right.margin - targetWidth;
		if (extraH < 0.0)
			extraH = 0.0;
		var extraV = freeHeight - c.top.margin - c.bottom.margin - targetHeight;
		if (extraV < 0.0)
			extraV = 0.0;

		c.left.position = left.position + left.padding + c.left.margin + alignmentOffset(alignment, extraH, true);
		c.top.position = top.position + top.padding + c.top.margin + alignmentOffset(alignment, extraV, false);
	}

	function layoutUniformCells(items:Array<LinearItem>, availablePrimary:Float) {
		var commonMin = 0.0;
		var commonPref = 0.0;
		var commonMax = Math.POSITIVE_INFINITY;
		var hasFill = false;

		for (item in items) {
			if (commonMin < item.cellMin)
				commonMin = item.cellMin;
			if (commonPref < item.cellPref)
				commonPref = item.cellPref;
			if (commonMax > item.cellMax)
				commonMax = item.cellMax;
			if (item.fillPrimary)
				hasFill = true;
		}

		if (commonMax < commonMin)
			commonMax = commonMin;
		if (commonPref < commonMin)
			commonPref = commonMin;
		if (commonMax < commonPref)
			commonPref = commonMax;

		var commonSize = commonPref;
		if (hasFill) {
			commonSize = availablePrimary / items.length;
			if (commonSize < commonMin)
				commonSize = commonMin;
			if (commonSize > commonMax)
				commonSize = commonMax;
		}

		for (item in items) {
			item.cellMin = commonMin;
			item.cellPref = commonPref;
			item.cellMax = commonMax;
			item.cellSize = commonSize;
		}
	}

	function distributeLinearCells(items:Array<LinearItem>, availablePrimary:Float) {
		var totalPref = 0.0;
		for (item in items)
			totalPref += item.cellPref;

		var delta = availablePrimary - totalPref;
		if (delta > 0.0)
			distributeLinearDelta(items, delta, true);
		else if (delta < 0.0)
			distributeLinearDelta(items, -delta, false);
	}

	function distributeLinearDelta(items:Array<LinearItem>, delta:Float, grow:Bool) {
		var remaining = delta;
		while (remaining > 0.0001) {
			var active = 0;
			var totalWeight = 0.0;
			var useStretch = false;

			if (grow)
				for (item in items)
					if (item.fillPrimary) {
						final capacity = item.cellMax - item.cellSize;
						if (capacity > 0.0001 && item.stretchPrimary > 0.0) {
							useStretch = true;
							break;
						}
					}

			for (item in items)
				if (item.fillPrimary) {
					final capacity = grow ? item.cellMax - item.cellSize : item.cellSize - item.cellMin;
					if (capacity > 0.0001) {
						active++;
						totalWeight += grow
							&& useStretch ? item.stretchPrimary > 0.0 ? item.stretchPrimary : 0.0 : Math.max(item.prefPrimary, 1.0);
					}
				}

			if (active == 0)
				break;

			var used = 0.0;
			for (item in items)
				if (item.fillPrimary) {
					final capacity = grow ? item.cellMax - item.cellSize : item.cellSize - item.cellMin;
					if (capacity > 0.0001) {
						final weight = grow
							&& useStretch ? item.stretchPrimary > 0.0 ? item.stretchPrimary : 0.0 : Math.max(item.prefPrimary, 1.0);
						if (weight <= 0.0)
							continue;
						var share = remaining * weight / totalWeight;
						if (share > capacity)
							share = capacity;
						if (grow)
							item.cellSize += share;
						else
							item.cellSize -= share;
						used += share;
					}
				}

			if (used <= 0.0001)
				break;
			remaining -= used;
		}
	}

	inline function preferredWidth(c:Element) {
		final l = c.layout;
		var value = l.preferredWidth;
		if (Math.isNaN(value))
			value = c.implicitWidth;
		if (Math.isNaN(value))
			value = c.width;
		return boundedWidth(c, value);
	}

	inline function preferredHeight(c:Element) {
		final l = c.layout;
		var value = l.preferredHeight;
		if (Math.isNaN(value))
			value = c.implicitHeight;
		if (Math.isNaN(value))
			value = c.height;
		return boundedHeight(c, value);
	}

	inline function minimumWidth(c:Element)
		return c.layout.minimumWidth;

	inline function minimumHeight(c:Element)
		return c.layout.minimumHeight;

	inline function maximumWidth(c:Element)
		return c.layout.maximumWidth;

	inline function maximumHeight(c:Element)
		return c.layout.maximumHeight;

	inline function boundedWidth(c:Element, value:Float)
		return clamp(value, c.layout.minimumWidth, c.layout.maximumWidth);

	inline function boundedHeight(c:Element, value:Float)
		return clamp(value, c.layout.minimumHeight, c.layout.maximumHeight);

	inline function clamp(value:Float, min:Float, max:Float):Float {
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	inline function resolveAlignment(alignment:Alignment, defaultHorizontal:Alignment, defaultVertical:Alignment, mirrorHorizontal:Bool):Alignment {
		var horizontal:Int = alignment & (AlignLeft | AlignHCenter | AlignRight);
		var vertical:Int = alignment & (AlignTop | AlignVCenter | AlignBottom);

		if (horizontal == 0)
			horizontal = defaultHorizontal;
		if (vertical == 0)
			vertical = defaultVertical;

		if (mirrorHorizontal) {
			if (horizontal & AlignLeft != 0)
				horizontal = AlignRight;
			else if (horizontal & AlignRight != 0)
				horizontal = AlignLeft;
		}

		return cast(horizontal | vertical);
	}

	function alignmentOffset(alignment:Alignment, extra:Float, horizontal:Bool) {
		if (horizontal) {
			if (alignment.matches(AlignRight))
				return extra;
			if (alignment.matches(AlignHCenter))
				return extra * 0.5;
		} else {
			if (alignment.matches(AlignBottom))
				return extra;
			if (alignment.matches(AlignVCenter))
				return extra * 0.5;
		}
		return 0.0;
	}
}
