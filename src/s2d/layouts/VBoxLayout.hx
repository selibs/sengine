package s2d.layouts;

import s2d.Anchors;
import s2d.Direction;
import s2d.layouts.DirLayout;
import s2d.layouts.LayoutCell;

using se.extensions.ArrayExt;

class VBoxLayout extends DirLayout<ElementVSlots, VLayoutCell> {
	var fillHeightCellsNum:Int = 0;
	@:inject(syncAvailableHeightPerCell) var availableHeight:Float = 0.0;
	@:inject(syncLayout) var availableHeightPerCell:Float = 0.0;

	public function new(name:String = "vBox", direction:Direction = TopToBottom) {
		super(name, direction);
	}

	@:slot(heightChanged)
	function syncHeight(previous:Float) {
		availableHeight += height - previous;
	}

	@:slot(top.positionChanged)
	function syncTopPosition(previous:Float) {
		if (direction & TopToBottom != 0)
			moveCells(top.position - previous);
	}

	@:slot(top.paddingChanged)
	function syncTopPadding(previous:Float) {
		availableHeight += previous - top.padding;
	}

	@:slot(bottom.positionChanged)
	function syncBottomPosition(previous:Float) {
		if (direction & BottomToTop != 0)
			moveCells(bottom.position - previous);
	}

	@:slot(bottom.paddingChanged)
	function syncBottomPadding(previous:Float) {
		availableHeight += previous - bottom.padding;
	}

	function getCell(el:Element) {
		var left = new LeftAnchor();
		left.bindTo(this.left);
		var right = new RightAnchor();
		right.bindTo(this.right);

		var top = new TopAnchor();
		var bottom = new BottomAnchor();
		if (direction & BottomToTop != 0) {
			if (cells.length == 0)
				bottom.bindTo(this.bottom);
			else {
				bottom.margin = spacing;
				bottom.bindTo(cells.last().cell.top);
			}
		} else {
			if (cells.length == 0)
				top.bindTo(this.top);
			else {
				top.margin = spacing;
				top.bindTo(cells.last().cell.bottom);
			}
		}
		return new VLayoutCell(el, left, top, right, bottom);
	}

	function setCellSlots(cell:VLayoutCell):CellSlots {
		return {
			requiredHeightChanged: (rh:Float) -> {
				if (!updating) {
					if (cell.fillHeight)
						syncAvailableHeightPerCell();
					else
						availableHeight += rh - cell.requiredHeight;
				}
			},
			fillHeightChanged: (fh:Bool) -> {
				if (!fh && cell.el.layout.fillHeight) {
					++fillHeightCellsNum;
					availableHeight += cell.requiredHeight;
				} else if (fh && !cell.el.layout.fillHeight) {
					--fillHeightCellsNum;
					@:privateAccess cell.syncRequiredHeight();
				}
			}
		};
	}

	function cellAdded(cell:VLayoutCell) {
		if (cell.fillHeight) {
			++fillHeightCellsNum;
			syncAvailableHeightPerCell();
		} else
			availableHeight -= cell.requiredHeight + (cells.length > 1 ? spacing : 0.0);
	}

	function cellRemoved(cell:VLayoutCell) {
		if (cell.fillHeight) {
			--fillHeightCellsNum;
			syncAvailableHeightPerCell();
		} else
			availableHeight += cell.requiredHeight + (cells.length > 1 ? spacing : 0.0);
	}

	function syncAvailableHeightPerCell() {
		if (cells.length > 0) {
			var fs = availableHeight;
			if (fillHeightCellsNum > 0) {
				updating = true;
				final perCell = availableHeight / fillHeightCellsNum;
				for (cellSlots in cells) {
					final cell = cellSlots.cell;
					if (cell.fillHeight) {
						final w = Layout.clampHeight(cell.el, perCell);
						cell.requiredHeight = w;
						fs -= w;
					}
				}
				updating = false;
			}
			availableHeightPerCell = Math.max(0.0, fs / cells.length);
		}
	}

	function syncLayout() {
		if (direction & BottomToTop != 0)
			for (cellSlots in cells) {
				final cell = cellSlots.cell;
				cell.top.position = cell.bottom.position - cell.requiredHeight + availableHeightPerCell;
			}
		else
			for (cellSlots in cells) {
				final cell = cellSlots.cell;
				cell.bottom.position = cell.top.position + cell.requiredHeight + availableHeightPerCell;
			}
	}

	function moveCells(d:Float) {
		for (cellSlots in cells) {
			cellSlots.cell.top.position += d;
			cellSlots.cell.bottom.position += d;
		}
	}

	function syncSpacing(d:Float) {
		if (cells.length > 1) {
			if (direction & BottomToTop != 0)
				for (cellSlots in cells.slice(1))
					cellSlots.cell.bottom.margin = spacing;
			else
				for (cellSlots in cells.slice(1))
					cellSlots.cell.top.margin = spacing;
			availableHeight += d * (cells.length - 1);
		}
	}
}
