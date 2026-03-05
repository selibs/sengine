package s2d.layouts;

import s2d.Alignment;

class BoxLayout extends Element {
	var slots:Map<Element, BoxLayoutSlots> = [];
	@:inject(syncFreeWidth) var freeWidth:Float = 0.0;
	@:inject(syncFreeHeight) var freeHeight:Float = 0.0;
	var fillWidthElements:Array<Element> = [];
	var fillHeightElements:Array<Element> = [];

	public function new(name:String = "box") {
		super(name);
	}

	override function __childAdded__(child:Element) {
		super.__childAdded__(child);
		fit(child);
		var dirtyWidthSlot = w -> {
			if (child.layout.fillWidth)
				child.width = Layout.clampWidth(child, freeWidth);
		}
		var dirtyHeightSlot = w -> {
			if (child.layout.fillHeight)
				child.height = Layout.clampWidth(child, freeHeight);
		}
		var childSlots:BoxLayoutSlots = {
			alignmentChanged: _ -> fit(child),
			fillWidthChanged: fw -> {
				if (!fw && child.layout.fillWidth) {
					fillWidthElements.push(child);
					fitH(child);
				} else if (fw && !child.layout.fillWidth) {
					fillWidthElements.remove(child);
					fitH(child);
				}
			},
			minimumWidthChanged: dirtyWidthSlot,
			maximumWidthChanged: dirtyWidthSlot,
			preferredWidthChanged: dirtyWidthSlot,
			fillHeightChanged: fh -> {
				if (!fh && child.layout.fillHeight) {
					fillHeightElements.push(child);
					fitV(child);
				} else if (fh && !child.layout.fillHeight) {
					fillHeightElements.remove(child);
					fitV(child);
				}
			},
			minimumHeightChanged: dirtyHeightSlot,
			maximumHeightChanged: dirtyHeightSlot,
			preferredHeightChanged: dirtyHeightSlot
		};
		child.layout.onAlignmentChanged(childSlots.alignmentChanged);
		child.layout.onFillWidthChanged(childSlots.fillWidthChanged);
		child.layout.onMinimumWidthChanged(childSlots.minimumWidthChanged);
		child.layout.onMaximumWidthChanged(childSlots.maximumWidthChanged);
		child.layout.onPreferredWidthChanged(childSlots.preferredWidthChanged);
		child.layout.onFillHeightChanged(childSlots.fillHeightChanged);
		child.layout.onMinimumHeightChanged(childSlots.minimumHeightChanged);
		child.layout.onMaximumHeightChanged(childSlots.maximumHeightChanged);
		child.layout.onPreferredHeightChanged(childSlots.preferredHeightChanged);
		slots.set(child, childSlots);
		if (child.layout.fillWidth)
			fillWidthElements.push(child);
		if (child.layout.fillHeight)
			fillHeightElements.push(child);
	}

	override function __childRemoved__(child:Element) {
		var childSlots = slots.get(child);
		child.anchors.clear();
		child.layout.offAlignmentChanged(childSlots.alignmentChanged);
		child.layout.offFillWidthChanged(childSlots.fillWidthChanged);
		child.layout.offMinimumWidthChanged(childSlots.minimumWidthChanged);
		child.layout.offMaximumWidthChanged(childSlots.maximumWidthChanged);
		child.layout.offPreferredWidthChanged(childSlots.preferredWidthChanged);
		child.layout.offFillHeightChanged(childSlots.fillHeightChanged);
		child.layout.offMinimumHeightChanged(childSlots.minimumHeightChanged);
		child.layout.offMaximumHeightChanged(childSlots.maximumHeightChanged);
		child.layout.offPreferredHeightChanged(childSlots.preferredHeightChanged);
		if (child.layout.fillWidth)
			fillWidthElements.remove(child);
		if (child.layout.fillHeight)
			fillHeightElements.remove(child);
		slots.remove(child);
		child.anchors.clear();
	}

	@:slot(widthChanged)
	function syncWidth(previous:Float) {
		freeWidth += width - previous;
	}

	@:slot(left.paddingChanged)
	function syncLeftPadding(previous:Float) {
		freeWidth += previous - left.padding;
	}

	@:slot(right.paddingChanged)
	function syncRightPadding(previous:Float) {
		freeWidth += previous - right.padding;
	}

	@:slot(heightChanged)
	function syncHeight(previous:Float) {
		freeHeight += height - previous;
	}

	@:slot(top.paddingChanged)
	function syncTopPadding(previous:Float) {
		freeHeight += previous - top.padding;
	}

	@:slot(bottom.paddingChanged)
	function syncBottomPadding(previous:Float) {
		freeHeight += previous - bottom.padding;
	}

	function syncFreeWidth() {
		for (el in fillWidthElements)
			el.width = Layout.clampWidth(el, freeWidth);
	}

	function syncFreeHeight() {
		for (el in fillHeightElements)
			el.height = Layout.clampHeight(el, freeHeight);
	}

	function fit(el:Element) {
		fitH(el);
		fitV(el);
	}

	function fitH(el:Element) {
		el.anchors.clearH();
		if (el.layout.fillWidth)
			el.width = Layout.clampWidth(el, freeWidth);
		if (el.layout.alignment & AlignRight != 0)
			el.anchors.right = right;
		else if (el.layout.alignment & AlignHCenter != 0)
			el.anchors.hCenter = hCenter;
		else
			el.anchors.left = left;
	}

	function fitV(el:Element) {
		el.anchors.clearV();
		if (el.layout.fillHeight)
			el.height = Layout.clampHeight(el, freeHeight);
		if (el.layout.alignment & AlignBottom != 0)
			el.anchors.bottom = bottom;
		else if (el.layout.alignment & AlignVCenter != 0)
			el.anchors.vCenter = vCenter;
		else
			el.anchors.top = top;
	}
}

private typedef BoxLayoutSlots = {
	alignmentChanged:Float->Void,
	fillWidthChanged:Bool->Void,
	minimumWidthChanged:Float->Void,
	maximumWidthChanged:Float->Void,
	preferredWidthChanged:Float->Void,
	fillHeightChanged:Bool->Void,
	minimumHeightChanged:Float->Void,
	maximumHeightChanged:Float->Void,
	preferredHeightChanged:Float->Void
}
