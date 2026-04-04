package s.ui.elements.positioners;

import s.ui.Anchors;
import s.ui.Direction;

class Flow extends Positioner {
	@:attr public var axis:Axis;

	public function new(axis:Axis = Horizontal, direction:Direction = LeftToRight) {
		super(direction);
		this.axis = axis;
	}

	function syncFlow() {
		if (axisIsDirty)
			flowIsDirty = true;

		final primaryHorizontal = axis == Horizontal;
		final forward = primaryHorizontal ? direction & RightToLeft == 0 : direction & BottomToTop == 0;
		final crossForward = primaryHorizontal ? direction & BottomToTop == 0 : direction & RightToLeft == 0;

		final pStart:AnchorLine = primaryHorizontal ? left : top;
		final pEnd:AnchorLine = primaryHorizontal ? right : bottom;
		final cStart:AnchorLine = primaryHorizontal ? top : left;
		final cEnd:AnchorLine = primaryHorizontal ? bottom : right;

		var boundsAreDirty = pStart.positionIsDirty || pEnd.positionIsDirty || pStart.paddingIsDirty || pEnd.paddingIsDirty || cStart.positionIsDirty
			|| cEnd.positionIsDirty || cStart.paddingIsDirty || cEnd.paddingIsDirty;
		var offsetIsDirty = flowIsDirty || axisIsDirty || directionIsDirty || spacingIsDirty || boundsAreDirty;

		final start = forward ? pStart.position + pStart.padding : pEnd.position - pEnd.padding;
		final limit = forward ? pEnd.position - pEnd.padding : pStart.position + pStart.padding;
		var base = start;

		var lineBase = crossForward ? cStart.position + cStart.padding : cEnd.position - cEnd.padding;
		var lineSize = 0.0;
		var hasInLine = false;

		for (c in children) {
			var childDirty = offsetIsDirty;

			final cpStart:AnchorLine = primaryHorizontal ? c.left : c.top;
			final cpEnd:AnchorLine = primaryHorizontal ? c.right : c.bottom;
			final ccStart:AnchorLine = primaryHorizontal ? c.top : c.left;
			final ccEnd:AnchorLine = primaryHorizontal ? c.bottom : c.right;

			final pLead = forward ? cpStart : cpEnd;
			final pTrail = forward ? cpEnd : cpStart;
			final cLead = crossForward ? ccStart : ccEnd;
			final cTrail = crossForward ? ccEnd : ccStart;

			var lm = pLead.marginIsDirty;
			var rm = pTrail.marginIsDirty;
			var lp = pLead.positionIsDirty;
			var rp = pTrail.positionIsDirty;

			var tm = cLead.marginIsDirty;
			var bm = cTrail.marginIsDirty;
			var tp = cLead.positionIsDirty;
			var bp = cTrail.positionIsDirty;

			childDirty = childDirty
				|| c.visibleIsDirty
				|| c.visible
				&& (lm || rm || lp || rp || tm || bm || tp || bp || c.widthIsDirty || c.heightIsDirty);

			if (c.visible) {
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
					offsetIsDirty = true;
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

				syncChild(c);

				if (forward)
					base = pTrail.position + mEnd + spacing;
				else
					base = pTrail.position - mEnd - spacing;

				final lineCandidate = crossSize + crossStart + crossEnd;
				if (lineCandidate > lineSize)
					lineSize = lineCandidate;
				hasInLine = true;
			} else {
				syncChild(c);
			}

			offsetIsDirty = childDirty;
		}
	}
}
