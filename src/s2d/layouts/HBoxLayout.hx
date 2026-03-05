package s2d.layouts;

import s2d.Anchors;
import s2d.Direction;
import s2d.layouts.DirLayout;
import s2d.layouts.LayoutCell;

using se.extensions.ArrayExt;

class HBoxLayout extends DirLayout<ElementHSlots, HLayoutCell> {
	var fillWidthCellsNum:Int = 0;
	@:inject(syncAvailableWidthPerCell) var availableWidth:Float = 0.0;
	@:inject(syncLayout) var availableWidthPerCell:Float = 0.0;

	public function new(name:String = "hBox", direction:Direction = LeftToRight) {
		super(name, direction);
	}

	@:slot(widthChanged)
	function syncWidth(previous:Float) {
		availableWidth += width - previous;
	}

	@:slot(left.positionChanged)
	function syncLeftPosition(previous:Float) {
		if (direction & LeftToRight != 0)
			moveCells(left.position - previous);
	}

	@:slot(left.paddingChanged)
	function syncLeftPadding(previous:Float) {
		availableWidth += previous - left.padding;
	}

	@:slot(right.paddingChanged)
	function syncRightPadding(previous:Float) {
		availableWidth += previous - right.padding;
	}

	@:slot(right.positionChanged)
	function syncRightPosition(previous:Float) {
		if (direction & RightToLeft != 0)
			moveCells(right.position - previous);
	}

	function getCell(el:Element) {
		var top = new TopAnchor();
		top.bindTo(this.top);
		var bottom = new BottomAnchor();
		bottom.bindTo(this.bottom);

		var left = new LeftAnchor();
		var right = new RightAnchor();
		if (direction & RightToLeft != 0) {
			if (cells.length == 0)
				right.bindTo(this.right);
			else {
				right.margin = spacing;
				right.bindTo(cells.last().cell.left);
			}
		} else {
			if (cells.length == 0)
				left.bindTo(this.left);
			else {
				left.margin = spacing;
				left.bindTo(cells.last().cell.right);
			}
		}
		return new HLayoutCell(el, left, top, right, bottom);
	}

	function setCellSlots(cell:HLayoutCell):CellSlots {
		return {
			requiredWidthChanged: (rw:Float) -> {
				if (!updating) {
					if (cell.fillWidth)
						syncAvailableWidthPerCell();
					else
						availableWidth += rw - cell.requiredWidth;
				}
			},
			fillWidthChanged: (fw:Bool) -> {
				if (!fw && cell.el.layout.fillWidth) {
					++fillWidthCellsNum;
					availableWidth += cell.requiredWidth;
				} else if (fw && !cell.el.layout.fillWidth) {
					--fillWidthCellsNum;
					@:privateAccess cell.syncRequiredWidth();
				}
			}
		}
	}

	function cellAdded(cell:HLayoutCell) {
		if (cell.fillWidth) {
			++fillWidthCellsNum;
			syncAvailableWidthPerCell();
		} else
			availableWidth -= cell.requiredWidth + (cells.length > 1 ? spacing : 0.0);
	}

	function cellRemoved(cell:HLayoutCell) {
		if (cell.fillWidth) {
			--fillWidthCellsNum;
			syncAvailableWidthPerCell();
		} else
			availableWidth += cell.requiredWidth + (cells.length > 1 ? spacing : 0.0);
	}

	function syncAvailableWidthPerCell() {
		if (cells.length > 0) {
			var fs = availableWidth;
			if (fillWidthCellsNum > 0) {
				updating = true;
				final perCell = availableWidth / fillWidthCellsNum;
				for (cellSlots in cells) {
					final cell = cellSlots.cell;
					if (cell.fillWidth) {
						final w = Layout.clampWidth(cell.el, perCell);
						cell.requiredWidth = w;
						fs -= w;
					}
				}
				updating = false;
			}
			availableWidthPerCell = Math.max(0.0, fs / cells.length);
		}
	}

	function syncLayout() {
		if (direction & RightToLeft != 0)
			for (cellSlots in cells) {
				final cell = cellSlots.cell;
				cell.left.position = cell.right.position - cell.requiredWidth + availableWidthPerCell;
			}
		else
			for (cellSlots in cells) {
				final cell = cellSlots.cell;
				cell.right.position = cell.left.position + cell.requiredWidth + availableWidthPerCell;
			}
	}

	function moveCells(d:Float) {
		for (cellSlots in cells) {
			cellSlots.cell.left.position += d;
			cellSlots.cell.right.position += d;
		}
	}

	function syncSpacing(d:Float) {
		if (cells.length > 1) {
			if (direction & RightToLeft != 0)
				for (cellSlots in cells.slice(1))
					cellSlots.cell.right.margin = spacing;
			else
				for (cellSlots in cells.slice(1))
					cellSlots.cell.left.margin = spacing;
			availableWidth += d * (cells.length - 1);
		}
	}
}
