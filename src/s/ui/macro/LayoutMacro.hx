package s.ui.macro;

import haxe.macro.Expr;

using s.extensions.StringExt;

class LayoutMacro {
	public static macro function updateLayoutFlow(s:String, e:String, p:String, l:String, cp:String, cl:String) {
		var sCap = s.capitalize();
		var eCap = e.capitalize();
		var pCap = p.capitalize();
		var lCap = l.capitalize();
		var cpCap = cp.capitalize();
		var clCap = cl.capitalize();

		var sRef = macro $i{s};
		var dRef = macro $i{'${eCap}To${sCap}'};
		var rectPRef = macro $i{'rect$pCap'};
		var rectLRef = macro $i{'rect$lCap'};
		var rectCPRef = macro $i{'rect$cpCap'};
		var rectCLRef = macro $i{'rect$clCap'};
		var rectPDirtyRef = macro $i{'rect${pCap}Dirty'};
		var rectLDirtyRef = macro $i{'rect${lCap}Dirty'};
		var rectCPDirtyRef = macro $i{'rect${cpCap}Dirty'};
		var rectCLDirtyRef = macro $i{'rect${clCap}Dirty'};

		var clampL = 'clamp$lCap';
		var fillL = 'fill$lCap';
		var fillLFactor = '${fillL}Factor';
		var minimumL = 'minimum$lCap';
		var maximumL = 'maximum$lCap';
		var preferredL = 'preferred$lCap';
		var primaryDirty = l == "width" ? "horizontalDirty" : "verticalDirty";
		var childLengthDirty = '${l}Dirty';

		function updateCell(cell:Expr, uniform:Bool)
			return macro {
				var cell = $cell;
				cell.$p = base;
				${
					if (uniform)
						macro cell.$l = freeSpacePerCell;
					else
						macro {
							if (!cell.$fillL || !Math.isNaN(cell.$preferredL))
								cell.$l = cell.object.$l;
							else
								cell.$l = cell.$minimumL + freeSpace * weights[cell];
							cell.$l += freeSpacePerCell;
						}
				}
				base += cell.$l + spacing;
				updateCell(cell);
			}

		return macro {
			var relayout = children.dirty || spacingDirty || directionDirty || uniformCellSizesDirty || $rectPDirtyRef || $rectLDirtyRef;
			if (!relayout)
				for (c in children) {
					final cell = c.layout;
					if (c.visibilityDirty
						|| c.parentDirty
						|| cell.$primaryDirty || (c.isVisible && !cell.$fillL && Math.isNaN(cell.$preferredL) && c.$childLengthDirty)) {
						relayout = true;
						break;
					}
				}

			if (!relayout) {
				var i = 0;
				while (i < cells.length) {
					final cell = cells[i];
					if ($rectCPDirtyRef)
						cell.$cp = $rectCPRef;
					if ($rectCLDirtyRef)
						cell.$cl = $rectCLRef;
					updateCell(cell);
					i++;
				}
				return;
			}

			var fixedSpace = 0.0;
			var totalWeight = 0.0;
			var weights:Map<AttachedLayout, Float> = [];

			cells.resize(0);
			for (c in children) {
				if (!c.isVisible)
					continue;

				final cell = c.layout;
				cell.$cp = $rectCPRef;
				cell.$cl = $rectCLRef;
				cells.push(cell);

				if (!Math.isNaN(cell.$preferredL))
					fixedSpace += c.$l = cell.$clampL(cell.$preferredL);
				else if (!cell.$fillL)
					fixedSpace += c.$l;
				else {
					fixedSpace += cell.$minimumL;
					weights[cell] = Math.min(cell.$maximumL, $rectLRef) / $rectLRef;
					weights[cell] *= cell.$fillLFactor;
					totalWeight += weights[cell];
				}
			}

			if (cells.length <= 0)
				return;

			var base = $sRef.position + $sRef.padding;
			var freeSpace = Math.max(0.0, $rectLRef - fixedSpace - (cells.length - 1) * spacing);
			var freeSpacePerCell = 0.0;

			if (!uniformCellSizes) {
				if (totalWeight > 1)
					freeSpace /= totalWeight;
				else
					freeSpacePerCell = freeSpace * (1 - totalWeight) / cells.length;

				// *End*To*Start*
				if (direction.matches($dRef)) {
					var i = cells.length;
					while (i > 0)
						${updateCell(macro cells[--i], false)};
				}
				// fallback: *Start*To*End*
				else {
					var i = 0;
					while (i < cells.length)
						${updateCell(macro cells[i++], false)};
				}
			} else {
				freeSpacePerCell = freeSpace / cells.length;

				// *End*To*Start*
				if (direction.matches($dRef)) {
					var i = cells.length;
					while (i > 0)
						${updateCell(macro cells[--i], true)};
				}
				// fallback: *Start*To*End*
				else {
					var i = 0;
					while (i < cells.length)
						${updateCell(macro cells[i++], true)};
				}
			}
		}
	}
}
