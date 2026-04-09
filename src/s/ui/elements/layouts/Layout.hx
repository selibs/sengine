package s.ui.elements.layouts;

import s.ui.Alignment;
import s.ui.AnchorLineAttribute;
import s.ui.Direction;
import s.ui.LayoutAttribute;
import s.ui.elements.ContainerElement;
import s.ui.elements.Element;

@:access(s.ui.LayoutAttribute)
@:access(s.ui.elements.ContainerElement)
@:access(s.ui.elements.Element)
@:access(s.ui.elements.positioners.Positioner)
class Layout extends ContainerElement {
	public static inline function clampWidth(el:Element, width:Float) {
		final l = el.layout;
		return Math.max(Math.min(width, l.maximumWidth), l.minimumWidth) + el.left.margin + el.right.margin;
	}

	public static inline function clampHeight(el:Element, height:Float) {
		final l = el.layout;
		return Math.max(Math.min(height, l.maximumHeight), l.minimumHeight) + el.top.margin + el.bottom.margin;
	}

	public static inline function align(el:Element, left:HorizontalAnchor, hCenter:HorizontalAnchor, right:HorizontalAnchor, top:VerticalAnchor,
			vCenter:VerticalAnchor, bottom:VerticalAnchor) {
		final l = el.layout;
		final a = el.anchors;
		a.clear();

		if (l.alignment != None) {
			if (l.alignment & AlignRight != 0) {
				a.right = right;
			} else if (l.alignment & AlignHCenter != 0)
				a.hCenter = hCenter;
			else
				a.left = left;

			if (l.alignment & AlignBottom != 0)
				a.bottom = bottom;
			else if (l.alignment & AlignVCenter != 0)
				a.vCenter = vCenter;
			else
				a.top = top;
		}
	}

	public static inline function syncHorizontalFlow(layout:DirectionalLayout)
		syncFlow(layout, true, false);

	public static inline function syncVerticalFlow(layout:DirectionalLayout)
		syncFlow(layout, false, false);

	public static inline function syncHorizontalWrap(layout:FlowLayout)
		syncFlow(layout, true, true);

	public static inline function syncVerticalWrap(layout:FlowLayout)
		syncFlow(layout, false, true);

	static inline function syncFlow(layout:DirectionalLayout, horizontal:Bool, wrap:Bool) {
		final forward = horizontal ? (layout.direction & RightToLeft) == 0 : (layout.direction & BottomToTop) == 0;
		final crossForward = !wrap || (horizontal ? (layout.direction & BottomToTop) == 0 : (layout.direction & RightToLeft) == 0);
		final pStart = axisStart(layout, horizontal, true);
		final pEnd = axisEnd(layout, horizontal, true);
		final cStart = axisStart(layout, horizontal, false);
		final cEnd = axisEnd(layout, horizontal, false);

		final crossBoundsAreDirty = cStart.offsetDirty || cEnd.offsetDirty;
		final boundsAreDirty = crossBoundsAreDirty || pStart.offsetDirty || pEnd.offsetDirty;

		final start = forward ? pStart.position + pStart.padding : pEnd.position - pEnd.padding;
		final limit = forward ? pEnd.position - pEnd.padding : pStart.position + pStart.padding;
		var available = forward ? limit - start : start - limit;
		if (available < 0)
			available = 0;

		final crossStartPos = cStart.position + cStart.padding;
		final crossLimit = cEnd.position - cEnd.padding;
		var crossAvailable = crossLimit - crossStartPos;
		if (crossAvailable < 0)
			crossAvailable = 0;

		final children = layout.children;
		final count = children.count;
		final hierarchyDirty = children.dirty;
		final spacing = layout.spacing;
		final crossSpace = horizontal ? layout.spaceV : layout.spaceH;
		final crossSpaceDirty = horizontal ? layout.spaceVDirty : layout.spaceHDirty;

		var wrapLineCount = 0;
		var wrapFixed = 0.0;
		var wrapFillFactorSum = 0.0;
		var wrapAllFactorSum = 0.0;
		var wrapHasFill = false;
		var wrapMetricsDirty = hierarchyDirty;
		if (wrap) {
			var metricBase = start;
			var metricLineSize = 0.0;
			var metricLineFactor = 0.0;
			var metricLineHasFill = false;
			var metricHasInLine = false;
			var m = 0;
			while (m < count) {
				final c = children[m];
				if (!c.visible) {
					if (c.visibleDirty)
						wrapMetricsDirty = true;
					m++;
					continue;
				}

				final l = c.layout;
				final cpStart = axisStart(c, horizontal, true);
				final cpEnd = axisEnd(c, horizontal, true);
				final ccStart = axisStart(c, horizontal, false);
				final ccEnd = axisEnd(c, horizontal, false);

				final crossChanged = syncCrossSize(c, horizontal, ccStart, ccEnd, crossSpace, crossSpaceDirty, crossBoundsAreDirty, false, c.visibleDirty);
				if (crossChanged || syncPrimarySize(c, horizontal, cpStart, cpEnd))
					wrapMetricsDirty = true;

				final fill = axisCanFill(l, horizontal, true);
				final fillDirty = axisFillDirty(l, horizontal, true);
				final addFixed = fill ? axisMinimum(l, horizontal, true) : axisSize(c, horizontal, true);
				final needed = cpStart.margin + addFixed + cpEnd.margin;
				if (fillDirty)
					wrapMetricsDirty = true;

				if (metricHasInLine && (forward ? metricBase + needed > limit : metricBase - needed < limit)) {
					wrapLineCount++;
					wrapFixed += metricLineSize;
					if (metricLineHasFill) {
						wrapHasFill = true;
						wrapFillFactorSum += metricLineFactor;
					} else
						wrapAllFactorSum += metricLineFactor;

					metricBase = start;
					metricLineSize = 0.0;
					metricLineFactor = 0.0;
					metricLineHasFill = false;
					metricHasInLine = false;
					continue;
				}

				final crossFill = axisCanFill(l, horizontal, false);
				final crossFillDirty = axisFillDirty(l, horizontal, false);
				final lineCandidate = (crossFill ? axisMinimum(l, horizontal, false) : axisSize(c, horizontal, false)) + ccStart.margin + ccEnd.margin;
				if (lineCandidate > metricLineSize)
					metricLineSize = lineCandidate;

				final crossFactor = axisFactor(l, horizontal, false);
				if (crossFactor > metricLineFactor)
					metricLineFactor = crossFactor;
				if (crossFill) {
					metricLineHasFill = true;
					if (crossFillDirty || axisFactorDirty(l, horizontal, false))
						wrapMetricsDirty = true;
				} else if (crossFillDirty || axisFactorDirty(l, horizontal, false))
					wrapMetricsDirty = true;

				metricBase = forward ? metricBase + needed + spacing : metricBase - needed - spacing;
				metricHasInLine = true;
				m++;
			}

			if (metricHasInLine) {
				wrapLineCount++;
				wrapFixed += metricLineSize;
				if (metricLineHasFill) {
					wrapHasFill = true;
					wrapFillFactorSum += metricLineFactor;
				} else
					wrapAllFactorSum += metricLineFactor;
			}
		}

		var wrapRemaining = 0.0;
		var wrapUseFallback = false;
		if (wrap) {
			wrapRemaining = crossAvailable - wrapFixed - (wrapLineCount > 1 ? spacing * (wrapLineCount - 1) : 0.0);
			if (wrapRemaining < 0)
				wrapRemaining = 0;
			wrapUseFallback = !wrapHasFill && wrapAllFactorSum > 0;
		}

		var lineBase = crossForward ? crossStartPos : cEnd.position - cEnd.padding;
		var offsetCarry = hierarchyDirty || layout.flowDirty || layout.flowLayoutDirty || boundsAreDirty || wrapMetricsDirty;
		var i = 0;
		while (i < count) {
			var base = start;
			var lineSize = wrap ? 0.0 : crossAvailable;
			var hasInLine = false;
			var visibleCount = 0;
			var fixed = 0.0;
			var margins = 0.0;
			var fillFactorSum = 0.0;
			var allFactorSum = 0.0;
			var hasFill = false;
			var anyFactorDirty = false;
			var lineCrossFactor = 0.0;
			var lineHasCrossFill = false;
			var lineFactorDirty = false;
			var sizeChanged = false;

			var j = i;
			while (j < count) {
				final c = children[j];
				if (!c.visible) {
					if (c.visibleDirty)
						sizeChanged = true;
					j++;
					continue;
				}

				final l = c.layout;
				if (!wrap && l.alignmentDirty)
					clearCrossAnchors(c, horizontal);

				final cpStart = axisStart(c, horizontal, true);
				final cpEnd = axisEnd(c, horizontal, true);
				final ccStart = axisStart(c, horizontal, false);
				final ccEnd = axisEnd(c, horizontal, false);

				final crossChanged = syncCrossSize(c, horizontal, ccStart, ccEnd, crossSpace, crossSpaceDirty, crossBoundsAreDirty, !wrap, c.visibleDirty);
				if (crossChanged)
					sizeChanged = true;
				if (syncPrimarySize(c, horizontal, cpStart, cpEnd))
					sizeChanged = true;

				final fill = axisCanFill(l, horizontal, true);
				final fillDirty = axisFillDirty(l, horizontal, true);
				final addFixed = fill ? axisMinimum(l, horizontal, true) : axisSize(c, horizontal, true);
				final needed = cpStart.margin + addFixed + cpEnd.margin;

				if (fillDirty)
					sizeChanged = true;

				if (wrap && hasInLine && (forward ? base + needed > limit : base - needed < limit)) {
					sizeChanged = true;
					break;
				}

				if (fill) {
					if (axisFactorDirty(l, horizontal, true))
						sizeChanged = true;
					hasFill = true;
					fillFactorSum += axisFactor(l, horizontal, true);
				} else if (!hasFill) {
					if (axisFactorDirty(l, horizontal, true))
						anyFactorDirty = true;
					allFactorSum += axisFactor(l, horizontal, true);
				}

				fixed += addFixed;

				margins += cpStart.margin + cpEnd.margin;
				visibleCount++;

				if (wrap) {
					final crossFill = axisCanFill(l, horizontal, false);
					final crossFillDirty = axisFillDirty(l, horizontal, false);
					var lineCandidate = (crossFill ? axisMinimum(l, horizontal, false) : axisSize(c, horizontal, false)) + ccStart.margin + ccEnd.margin;
					if (lineCandidate > lineSize)
						lineSize = lineCandidate;

					final crossFactor = axisFactor(l, horizontal, false);
					if (crossFactor > lineCrossFactor)
						lineCrossFactor = crossFactor;
					if (crossFill) {
						lineHasCrossFill = true;
						if (crossFillDirty || axisFactorDirty(l, horizontal, false))
							lineFactorDirty = true;
					} else if (crossFillDirty || axisFactorDirty(l, horizontal, false))
						lineFactorDirty = true;
				}

				base = forward ? base + needed + spacing : base - needed - spacing;
				hasInLine = true;
				j++;
			}
			final lineEnd = j;

			if (!hasFill && anyFactorDirty)
				sizeChanged = true;
			if (wrap && lineFactorDirty && (lineHasCrossFill || wrapUseFallback))
				sizeChanged = true;

			var remaining = available - margins - (visibleCount > 1 ? spacing * (visibleCount - 1) : 0.0) - fixed;
			if (remaining < 0)
				remaining = 0;

			final useFallback = !hasFill && allFactorSum > 0;
			var offsetDirty = offsetCarry || sizeChanged;
			var lineAlloc = 0.0;
			if (wrap && wrapRemaining > 0) {
				if (wrapFillFactorSum > 0) {
					if (lineHasCrossFill)
						lineAlloc = wrapRemaining * lineCrossFactor / wrapFillFactorSum;
				} else if (wrapUseFallback)
					lineAlloc = wrapRemaining * lineCrossFactor / wrapAllFactorSum;
			}
			final lineCellSize = lineSize + lineAlloc;
			var lineStartPos = crossForward ? lineBase : lineBase - lineCellSize;
			base = start;

			var k = i;
			while (k < lineEnd) {
				final c = children[k++];
				final l = c.layout;
				var childDirty = offsetDirty || c.visibleDirty || l.alignmentDirty;

				if (!c.visible) {
					layout.syncChild(c);
					offsetDirty = childDirty;
					continue;
				}

				final cpStart = axisStart(c, horizontal, true);
				final cpEnd = axisEnd(c, horizontal, true);
				final ccStart = axisStart(c, horizontal, false);
				final ccEnd = axisEnd(c, horizontal, false);
				final pLead = forward ? cpStart : cpEnd;

				if (cpStart.marginDirty || cpEnd.marginDirty || cpStart.positionDirty || cpEnd.positionDirty || ccStart.marginDirty || ccEnd.marginDirty
					|| ccStart.positionDirty || ccEnd.positionDirty || c.widthDirty || c.heightDirty)
					childDirty = true;

				final startMargin = cpStart.margin;
				final endMargin = cpEnd.margin;
				final fill = axisCanFill(l, horizontal, true);
				var alloc = 0.0;
				if (remaining > 0) {
					if (fillFactorSum > 0) {
						if (fill)
							alloc = remaining * axisFactor(l, horizontal, true) / fillFactorSum;
					} else if (useFallback)
						alloc = remaining * axisFactor(l, horizontal, true) / allFactorSum;
				}
				var cellSize = (fill ? axisMinimum(l, horizontal, true) : axisSize(c, horizontal, true)) + alloc;

				var slack = alloc;
				if (fill) {
					var target = clampSize(c, cellSize, horizontal, true) - (startMargin + endMargin);
					if (setAxisSize(c, horizontal, true, target))
						childDirty = true;
					slack = cellSize - target;
					if (target > cellSize)
						cellSize = target;
				}
				if (slack < 0)
					slack = 0;

				var cellSpan = startMargin + cellSize + endMargin;
				if (childDirty) {
					var cellStart = forward ? base : base - cellSpan;
					var childStart = cellStart + startMargin + alignOffset(l.alignment, slack, horizontal, true);

					if (forward)
						pLead.position = childStart;
					else
						pLead.position = childStart + axisSize(c, horizontal, true);

					final crossMargins = ccStart.margin + ccEnd.margin;
					if (wrap && axisCanFill(l, horizontal, false)) {
						final target = clampSize(c, lineCellSize - crossMargins, horizontal, false) - crossMargins;
						if (setAxisSize(c, horizontal, false, target))
							childDirty = true;
					}

					var extra = lineCellSize - (crossMargins + axisSize(c, horizontal, false));
					if (extra < 0)
						extra = 0;
					ccStart.position = lineStartPos + ccStart.margin + alignOffset(l.alignment, extra, horizontal, false);
				}

				layout.syncChild(c);
				base = forward ? base + cellSpan + spacing : base - cellSpan - spacing;

				offsetDirty = childDirty;
			}

			offsetCarry = offsetDirty;
			if (wrap && hasInLine)
				lineBase = crossForward ? lineBase + lineCellSize + spacing : lineBase - lineCellSize - spacing;

			i = lineEnd;
		}
	}

	static inline function axisStart(el:Element, horizontal:Bool, primary:Bool):AnchorLineAttribute
		return horizontal == primary ? el.left : el.top;

	static inline function axisEnd(el:Element, horizontal:Bool, primary:Bool):AnchorLineAttribute
		return horizontal == primary ? el.right : el.bottom;

	static inline function axisSize(el:Element, horizontal:Bool, primary:Bool):Float
		return horizontal == primary ? el.width : el.height;

	static inline function setAxisSize(el:Element, horizontal:Bool, primary:Bool, value:Float):Bool {
		var changed = false;
		if (horizontal == primary) {
			changed = el.width != value;
			if (changed)
				el.width = value;
		} else {
			changed = el.height != value;
			if (changed)
				el.height = value;
		}
		return changed;
	}

	static inline function axisFill(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return horizontal == primary ? l.fillWidth : l.fillHeight;

	static inline function axisCanFill(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return axisFill(l, horizontal, primary) && Math.isNaN(axisPreferred(l, horizontal, primary));

	static inline function axisFillDirty(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return horizontal == primary ? l.fillWidthDirty : l.fillHeightDirty;

	static inline function axisMinimum(l:LayoutAttribute, horizontal:Bool, primary:Bool):Float
		return horizontal == primary ? l.minimumWidth : l.minimumHeight;

	static inline function axisFactorDirty(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool {
		if (primary)
			return l.distributionDirty;
		return horizontal == primary ? l.fillWidthFactorDirty : l.fillHeightFactorDirty;
	}

	static inline function axisPreferred(l:LayoutAttribute, horizontal:Bool, primary:Bool):Float
		return horizontal == primary ? l.preferredWidth : l.preferredHeight;

	static inline function axisPreferredDirty(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return horizontal == primary ? l.preferredWidthDirty : l.preferredHeightDirty;

	static inline function axisMinMaxDirty(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return horizontal == primary ? l.minimumWidthDirty || l.maximumWidthDirty : l.minimumHeightDirty || l.maximumHeightDirty;

	static inline function axisLayoutDirty(l:LayoutAttribute, horizontal:Bool, primary:Bool):Bool
		return horizontal == primary ? l.horizontalDirty : l.verticalDirty;

	static inline function axisFactor(l:LayoutAttribute, horizontal:Bool, primary:Bool):Float {
		var factor = horizontal == primary ? l.fillWidthFactor : l.fillHeightFactor;
		if (primary) {
			var weight = l.weight;
			if (weight < 0)
				weight = 0;
			factor *= weight;
		}
		return factor;
	}

	static inline function clampSize(el:Element, size:Float, horizontal:Bool, primary:Bool):Float
		return horizontal == primary ? clampWidth(el, size) : clampHeight(el, size);

	static inline function syncPrimarySize(c:Element, horizontal:Bool, pStart:AnchorLineAttribute, pEnd:AnchorLineAttribute):Bool {
		final l = c.layout;
		final minMaxDirty = axisMinMaxDirty(l, horizontal, true);
		final preferred = axisPreferred(l, horizontal, true);
		final fill = axisCanFill(l, horizontal, true);
		final margins = pStart.margin + pEnd.margin;
		var changed = false;

		if (!Math.isNaN(preferred) && (axisPreferredDirty(l, horizontal, true) || minMaxDirty))
			changed = setAxisSize(c, horizontal, true, clampSize(c, preferred, horizontal, true) - margins);
		else if (!fill && minMaxDirty)
			changed = setAxisSize(c, horizontal, true, clampSize(c, axisSize(c, horizontal, true), horizontal, true) - margins);
		else
			changed = fill && minMaxDirty;
		return changed;
	}

	static inline function syncCrossSize(c:Element, horizontal:Bool, cStart:AnchorLineAttribute, cEnd:AnchorLineAttribute, crossSpace:Float,
			crossSpaceDirty:Bool, crossBoundsAreDirty:Bool, fill:Bool, visibleDirty:Bool):Bool {
		final l = c.layout;
		final minMaxDirty = axisMinMaxDirty(l, horizontal, false);
		final preferred = axisPreferred(l, horizontal, false);
		final canFill = axisCanFill(l, horizontal, false);
		final margins = cStart.margin + cEnd.margin;
		var changed = false;

		if (!Math.isNaN(preferred) && (axisPreferredDirty(l, horizontal, false) || minMaxDirty))
			changed = setAxisSize(c, horizontal, false, clampSize(c, preferred, horizontal, false) - margins);
		else if (fill
			&& canFill
			&& (visibleDirty
				|| axisPreferredDirty(l, horizontal, false)
				|| minMaxDirty
				|| axisFillDirty(l, horizontal, false)
				|| axisFactorDirty(l, horizontal, false)
				|| crossSpaceDirty
				|| crossBoundsAreDirty
				|| cStart.marginDirty
				|| cEnd.marginDirty))
			changed = setAxisSize(c, horizontal, false, clampSize(c, crossSpace * axisFactor(l, horizontal, false) - margins, horizontal, false) - margins);
		else if (!canFill && minMaxDirty)
			changed = setAxisSize(c, horizontal, false, clampSize(c, axisSize(c, horizontal, false), horizontal, false) - margins);
		else
			changed = canFill && minMaxDirty;
		return changed;
	}

	static inline function clearCrossAnchors(c:Element, horizontal:Bool) {
		if (horizontal) {
			if (c.anchors.top != null || c.anchors.vCenter != null || c.anchors.bottom != null)
				c.anchors.clearV();
		} else if (c.anchors.left != null || c.anchors.hCenter != null || c.anchors.right != null)
			c.anchors.clearH();
	}

	static inline function alignOffset(alignment:Alignment, value:Float, horizontal:Bool, primary:Bool):Float {
		var offset = 0.0;
		if (horizontal == primary) {
			if (alignment & AlignRight != 0)
				offset = value;
			else if (alignment & AlignHCenter != 0)
				offset = value * 0.5;
		} else {
			if (alignment & AlignBottom != 0)
				offset = value;
			else if (alignment & AlignVCenter != 0)
				offset = value * 0.5;
		}
		return offset;
	}

	override function syncChild(c:Element) {
		final l = c.layout;

		if (l.alignmentDirty)
			Layout.align(c, left, hCenter, right, top, vCenter, bottom);

		final lHDirty = l.minimumWidthDirty || l.maximumWidthDirty;
		final hMargins = c.left.margin + c.right.margin;
		if (!Math.isNaN(l.preferredWidth) && l.horizontalDirty)
			c.width = Layout.clampWidth(c, l.preferredWidth) - hMargins;
		else if (Math.isNaN(l.preferredWidth) && l.fillWidth && (l.horizontalDirty || spaceHDirty))
			c.width = Layout.clampWidth(c, spaceH * l.fillWidthFactor) - hMargins;

		final lVDirty = l.minimumHeightDirty || l.maximumHeightDirty;
		final vMargins = c.top.margin + c.bottom.margin;
		if (!Math.isNaN(l.preferredHeight) && l.verticalDirty)
			c.height = Layout.clampHeight(c, l.preferredHeight) - vMargins;
		else if (Math.isNaN(l.preferredHeight) && l.fillHeight && (l.verticalDirty || spaceVDirty))
			c.height = Layout.clampHeight(c, spaceV * l.fillHeightFactor) - vMargins;

		super.syncChild(c);
	}
}
