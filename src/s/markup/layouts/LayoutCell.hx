package s.markup.layouts;

import s.markup.Anchors;
import s.markup.Alignment;

@:dox(hide)
abstract class LayoutCell<S:ElementSlots> implements s.shortcut.Shortcut {
	var slots:S;

	public var el:Element;

	public var left:HorizontalAnchor;
	public var hCenter:HorizontalAnchor;
	public var right:HorizontalAnchor;
	public var top:VerticalAnchor;
	public var vCenter:VerticalAnchor;
	public var bottom:VerticalAnchor;

	@:signal public var requiredWidth:Float = 0.0;
	@:signal public var requiredHeight:Float = 0.0;

	@:alias public var fillWidth:Bool = el.layout.fillWidth;
	@:alias public var fillHeight:Bool = el.layout.fillHeight;

	public function new(el:Element, left:HorizontalAnchor, top:VerticalAnchor, right:HorizontalAnchor, bottom:VerticalAnchor) {
		this.el = el;

		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
		hCenter = new HCenterAnchor((left.position + right.position) * 0.5);
		vCenter = new VCenterAnchor((top.position + bottom.position) * 0.5);
		left.onPositionChanged(p -> hCenter.position += (left.position - p) * 0.5);
		right.onPositionChanged(p -> hCenter.position += (right.position - p) * 0.5);
		top.onPositionChanged(p -> vCenter.position += (top.position - p) * 0.5);
		bottom.onPositionChanged(p -> vCenter.position += (bottom.position - p) * 0.5);

		fit();
		add();
	}

	abstract public function addSlots():Void;

	abstract public function removeSlots():Void;

	public function add():Void {
		addSlots();
		slots.alignmentChanged = a -> fit();
		slots.fillWidthChanged = fw -> {
			if (fillWidth)
				bindH();
			else
				unbindH();
		};
		slots.fillHeightChanged = fh -> {
			if (fillHeight)
				bindV();
			else
				unbindV();
		};
		el.layout.onAlignmentChanged(slots.alignmentChanged);
		el.layout.onFillWidthChanged(slots.fillWidthChanged);
		el.layout.onFillHeightChanged(slots.fillHeightChanged);
		if (fillWidth)
			bindH();
		if (fillHeight)
			bindV();
	}

	public function remove():Void {
		removeSlots();
		el.layout.offAlignmentChanged(slots.alignmentChanged);
		el.layout.offFillWidthChanged(slots.fillWidthChanged);
		el.layout.offFillHeightChanged(slots.fillHeightChanged);
		if (fillWidth)
			unbindH();
		if (fillHeight)
			unbindV();
	}

	public function syncRequiredWidth() {
		if (!Math.isNaN(el.layout.preferredWidth))
			requiredWidth = Layout.clampWidth(el, el.layout.preferredWidth);
		else if (fillWidth)
			requiredWidth = Layout.clampWidth(el, right.position - left.position);
		else
			requiredWidth = Layout.clampWidth(el, el.width);
	}

	public function syncRequiredHeight() {
		if (!Math.isNaN(el.layout.preferredHeight))
			requiredHeight = Layout.clampHeight(el, el.layout.preferredHeight);
		else if (fillHeight)
			requiredHeight = Layout.clampHeight(el, bottom.position - top.position);
		else
			requiredHeight = Layout.clampHeight(el, el.height);
	}

	function fillH(_:Float = 0.0) {
		el.width = Layout.clampWidth(el, right.position - left.position);
	}

	function fillV(_:Float = 0.0) {
		el.height = Layout.clampHeight(el, bottom.position - top.position);
	}

	function bindH() {
		fillH();
		left.onPositionChanged(fillH);
		right.onPositionChanged(fillH);
	}

	function unbindH() {
		left.offPositionChanged(fillH);
		right.offPositionChanged(fillH);
	}

	function bindV() {
		fillV();
		top.onPositionChanged(fillV);
		bottom.onPositionChanged(fillV);
	}

	function unbindV() {
		top.offPositionChanged(fillV);
		bottom.offPositionChanged(fillV);
	}

	function fit() {
		el.anchors.clear();
		if (el.layout.alignment & AlignRight != 0)
			el.anchors.right = right;
		else if (el.layout.alignment & AlignHCenter != 0)
			el.anchors.hCenter = hCenter;
		else
			el.anchors.left = left;
		if (el.layout.alignment & AlignBottom != 0)
			el.anchors.bottom = bottom;
		else if (el.layout.alignment & AlignVCenter != 0)
			el.anchors.vCenter = vCenter;
		else
			el.anchors.top = top;
	}
}

@:dox(hide)
class HLayoutCell extends LayoutCell<ElementHSlots> {
	public function addSlots() {
		syncRequiredWidth();
		slots = {
			widthChanged: (_:Float) -> if (!fillWidth) syncRequiredWidth(),
			widthLayoutChanged: (_:Float) -> syncRequiredWidth()
		}
		el.onWidthChanged(slots.widthChanged);
		el.layout.onMinimumWidthChanged(slots.widthLayoutChanged);
		el.layout.onMaximumWidthChanged(slots.widthLayoutChanged);
		el.layout.onPreferredWidthChanged(slots.widthLayoutChanged);
	}

	public function removeSlots() {
		el.offWidthChanged(slots.widthChanged);
		el.layout.offMinimumWidthChanged(slots.widthLayoutChanged);
		el.layout.offMaximumWidthChanged(slots.widthLayoutChanged);
		el.layout.offPreferredWidthChanged(slots.widthLayoutChanged);
	}
}

@:dox(hide)
class VLayoutCell extends LayoutCell<ElementVSlots> {
	public function addSlots() {
		syncRequiredHeight();
		slots = {
			heightChanged: (_:Float) -> if (!fillHeight) syncRequiredHeight(),
			heightLayoutChanged: (_:Float) -> syncRequiredHeight()
		}
		el.onHeightChanged(slots.heightChanged);
		el.layout.onMinimumHeightChanged(slots.heightLayoutChanged);
		el.layout.onMaximumHeightChanged(slots.heightLayoutChanged);
		el.layout.onPreferredHeightChanged(slots.heightLayoutChanged);
	}

	public function removeSlots() {
		el.offHeightChanged(slots.heightChanged);
		el.layout.offMinimumHeightChanged(slots.heightLayoutChanged);
		el.layout.offMaximumHeightChanged(slots.heightLayoutChanged);
		el.layout.offPreferredHeightChanged(slots.heightLayoutChanged);
	}
}

@:dox(hide)
typedef ElementSlots = {
	?alignmentChanged:Alignment->Void,
	?fillWidthChanged:Bool->Void,
	?fillHeightChanged:Bool->Void
}

@:dox(hide)
typedef ElementHSlots = {
	> ElementSlots,
	widthChanged:Float->Void,
	widthLayoutChanged:Float->Void
}

@:dox(hide)
typedef ElementVSlots = {
	> ElementSlots,
	heightChanged:Float->Void,
	heightLayoutChanged:Float->Void
}
