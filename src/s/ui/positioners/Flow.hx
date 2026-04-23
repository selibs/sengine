package s.ui.positioners;

import s.ui.AttachedAnchors;
import s.ui.Direction;

class Flow extends Positioner {
	@:attr(flowLayout) public var axis:Axis;

	public function new(axis:Axis = Horizontal, direction:Direction = LeftToRight) {
		super(direction);
		this.axis = axis;
	}

	function updateFlow() {
		if (flowLayoutDirty)
			flowDirty = true;

		final primaryHorizontal = axis == Horizontal;
		final forward = primaryHorizontal ? direction & RightToLeft == 0 : direction & BottomToTop == 0;
		final crossForward = primaryHorizontal ? direction & BottomToTop == 0 : direction & RightToLeft == 0;

		final pStart:AttachedAnchorLine = primaryHorizontal ? left : top;
		final pEnd:AttachedAnchorLine = primaryHorizontal ? right : bottom;
		final cStart:AttachedAnchorLine = primaryHorizontal ? top : left;
		final cEnd:AttachedAnchorLine = primaryHorizontal ? bottom : right;

		var boundsAreDirty = pStart.offsetDirty || pEnd.offsetDirty || cStart.offsetDirty || cEnd.offsetDirty;
		var offsetDirty = children.dirty || flowDirty || flowLayoutDirty || boundsAreDirty;

		final start = forward ? pStart.position + pStart.padding : pEnd.position - pEnd.padding;
		final limit = forward ? pEnd.position - pEnd.padding : pStart.position + pStart.padding;
		var base = start;

		var lineBase = crossForward ? cStart.position + cStart.padding : cEnd.position - cEnd.padding;
		var lineSize = 0.0;
		var hasInLine = false;
		var items = children.copy();

		for (c in items) {
			var childDirty = offsetDirty;

			final cpStart:AttachedAnchorLine = primaryHorizontal ? c.left : c.top;
			final cpEnd:AttachedAnchorLine = primaryHorizontal ? c.right : c.bottom;
			final ccStart:AttachedAnchorLine = primaryHorizontal ? c.top : c.left;
			final ccEnd:AttachedAnchorLine = primaryHorizontal ? c.bottom : c.right;

			final pLead = forward ? cpStart : cpEnd;
			final pTrail = forward ? cpEnd : cpStart;
			final cLead = crossForward ? ccStart : ccEnd;
			final cTrail = crossForward ? ccEnd : ccStart;

			var lm = pLead.marginDirty;
			var rm = pTrail.marginDirty;
			var lp = pLead.positionDirty;
			var rp = pTrail.positionDirty;

			var tm = cLead.marginDirty;
			var bm = cTrail.marginDirty;
			var tp = cLead.positionDirty;
			var bp = cTrail.positionDirty;

			childDirty = childDirty
				|| c.dirty
				|| c.isVisibleDirty
				|| c.isVisible
				&& (lm || rm || lp || rp || tm || bm || tp || bp || c.widthDirty || c.heightDirty || c.xDirty || c.yDirty);

			if (c.isVisible) {
				final mStart = pLead.margin;
				final mEnd = pTrail.margin;
				final crossStart = cLead.margin;
				final crossEnd = cTrail.margin;

				inline function syncChild() {
					if (childDirty) {
					if (forward)
						pLead.position = base + mStart;
					else
						pLead.position = base - mStart;

					if (crossForward)
						cLead.position = lineBase + crossStart;
					else
						cLead.position = lineBase - crossStart;
				}

					updateChild(c);
				}

				syncChild();

				var primarySize = primaryHorizontal ? c.width : c.height;
				var crossSize = primaryHorizontal ? c.height : c.width;
				var needed = mStart + primarySize + mEnd;

				if (hasInLine && (forward ? base + needed > limit : base - needed < limit)) {
					base = start;
					lineBase = crossForward ? lineBase + lineSize + spacing : lineBase - lineSize - spacing;
					lineSize = 0.0;
					hasInLine = false;
					childDirty = true;

					syncChild();

					primarySize = primaryHorizontal ? c.width : c.height;
					crossSize = primaryHorizontal ? c.height : c.width;
					needed = mStart + primarySize + mEnd;
				}

				if (forward)
					base = pTrail.position + mEnd + spacing;
				else
					base = pTrail.position - mEnd - spacing;

				final lineCandidate = crossSize + crossStart + crossEnd;
				if (lineCandidate > lineSize)
					lineSize = lineCandidate;
				hasInLine = true;
			} else {
				updateChild(c);
			}

			offsetDirty = childDirty;
		}
	}
}
