package s.ui.positioners;

import s.ui.AnchorsAttribute;
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

		final pStart:AnchorLineAttribute = primaryHorizontal ? left : top;
		final pEnd:AnchorLineAttribute = primaryHorizontal ? right : bottom;
		final cStart:AnchorLineAttribute = primaryHorizontal ? top : left;
		final cEnd:AnchorLineAttribute = primaryHorizontal ? bottom : right;

		var boundsAreDirty = pStart.offsetDirty || pEnd.offsetDirty || cStart.offsetDirty || cEnd.offsetDirty;
		var offsetDirty = children.dirty || flowDirty || flowLayoutDirty || boundsAreDirty;

		final start = forward ? pStart.position + pStart.padding : pEnd.position - pEnd.padding;
		final limit = forward ? pEnd.position - pEnd.padding : pStart.position + pStart.padding;
		var base = start;

		var lineBase = crossForward ? cStart.position + cStart.padding : cEnd.position - cEnd.padding;
		var lineSize = 0.0;
		var hasInLine = false;

		for (c in children) {
			var childDirty = offsetDirty;

			final cpStart:AnchorLineAttribute = primaryHorizontal ? c.left : c.top;
			final cpEnd:AnchorLineAttribute = primaryHorizontal ? c.right : c.bottom;
			final ccStart:AnchorLineAttribute = primaryHorizontal ? c.top : c.left;
			final ccEnd:AnchorLineAttribute = primaryHorizontal ? c.bottom : c.right;

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
				|| c.isVisibleDirty
				|| c.isVisible
				&& (lm || rm || lp || rp || tm || bm || tp || bp || c.widthDirty || c.heightDirty);

			if (c.isVisible) {
				final mStart = pLead.margin;
				final mEnd = pTrail.margin;
				final crossStart = cLead.margin;
				final crossEnd = cTrail.margin;

				final primarySize = primaryHorizontal ? c.width : c.height;
				final crossSize = primaryHorizontal ? c.height : c.width;
				final needed = mStart + primarySize + mEnd;

				if (hasInLine && (forward ? base + needed > limit : base - needed < limit)) {
					base = start;
					lineBase = crossForward ? lineBase + lineSize + spacing : lineBase - lineSize - spacing;
					lineSize = 0.0;
					hasInLine = false;
					childDirty = true;
					offsetDirty = true;
				}

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
