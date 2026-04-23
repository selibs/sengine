package s.ui.macro;

import haxe.macro.Expr;

class LayoutMacro {
	public static macro function updateLayoutFlow(d:String, reversePrimary:Expr, mirrorHorizontal:Expr) {
		var primarySize:String, crossSize:String;
		var primaryStart:String, primaryCenter:String, primaryEnd:String;
		var crossStart:String, crossCenter:String, crossEnd:String;
		var freePrimary:String, freeCross:String;
		var primaryFill:String, crossFill:String;
		var primaryStretch:String;

		var primaryMin:Expr;
		var primaryPref:Expr;
		var primaryMax:Expr;
		var crossMin:Expr;
		var crossPref:Expr;
		var crossMax:Expr;
		var targetPrimary:Expr;
		var targetCross:Expr;
		var primaryReal:Expr;
		var crossReal:Expr;
		var primaryBaseStart:Expr;
		var crossBase:Expr;
		var primaryAlignEnd:Expr;
		var primaryAlignCenter:Expr;
		var crossAlignEnd:Expr;
		var crossAlignCenter:Expr;

		switch d {
			case "horizontal":
				primarySize = "width";
				crossSize = "height";
				primaryStart = "left";
				primaryCenter = "hCenter";
				primaryEnd = "right";
				crossStart = "top";
				crossCenter = "vCenter";
				crossEnd = "bottom";
				freePrimary = "freeWidth";
				freeCross = "freeHeight";
				primaryFill = "fillWidth";
				crossFill = "fillHeight";
				primaryStretch = "fillWidthFactor";
				primaryMin = macro minimumWidth(c);
				primaryPref = macro preferredWidth(c);
				primaryMax = macro maximumWidth(c);
				crossMin = macro minimumHeight(c);
				crossPref = macro preferredHeight(c);
				crossMax = macro maximumHeight(c);
				targetPrimary = macro boundedWidth(c, contentPrimary);
				targetCross = macro boundedHeight(c, contentCross);
				primaryReal = macro realWidth;
				crossReal = macro realHeight;
				primaryBaseStart = macro reverse ? right.position - right.padding : left.position + left.padding;
				crossBase = macro top.position + top.padding;
				primaryAlignEnd = macro s.ui.Alignment.AlignRight;
				primaryAlignCenter = macro s.ui.Alignment.AlignHCenter;
				crossAlignEnd = macro s.ui.Alignment.AlignBottom;
				crossAlignCenter = macro s.ui.Alignment.AlignVCenter;
			case "vertical":
				primarySize = "height";
				crossSize = "width";
				primaryStart = "top";
				primaryCenter = "vCenter";
				primaryEnd = "bottom";
				crossStart = "left";
				crossCenter = "hCenter";
				crossEnd = "right";
				freePrimary = "freeHeight";
				freeCross = "freeWidth";
				primaryFill = "fillHeight";
				crossFill = "fillWidth";
				primaryStretch = "fillHeightFactor";
				primaryMin = macro minimumHeight(c);
				primaryPref = macro preferredHeight(c);
				primaryMax = macro maximumHeight(c);
				crossMin = macro minimumWidth(c);
				crossPref = macro preferredWidth(c);
				crossMax = macro maximumWidth(c);
				targetPrimary = macro boundedHeight(c, contentPrimary);
				targetCross = macro boundedWidth(c, contentCross);
				primaryReal = macro realHeight;
				crossReal = macro realWidth;
				primaryBaseStart = macro reverse ? bottom.position - bottom.padding : top.position + top.padding;
				crossBase = macro left.position + left.padding;
				primaryAlignEnd = macro s.ui.Alignment.AlignBottom;
				primaryAlignCenter = macro s.ui.Alignment.AlignVCenter;
				crossAlignEnd = macro s.ui.Alignment.AlignRight;
				crossAlignCenter = macro s.ui.Alignment.AlignHCenter;
			default:
				throw "Invalid axis: " + d;
		}

		final psRef = macro $i{primaryStart};
		final peRef = macro $i{primaryEnd};
		final csRef = macro $i{crossStart};
		final pSizeRef = macro $i{primarySize};
		final cSizeRef = macro $i{crossSize};
		final freePrimaryRef = macro $i{freePrimary};
		final freeCrossRef = macro $i{freeCross};
		final primaryFillRef = macro $i{primaryFill};
		final crossFillRef = macro $i{crossFill};
		final primaryStretchRef = macro $i{primaryStretch};

		return macro {
			final items = [];
			final reverse = $reversePrimary;
			final mirror = $mirrorHorizontal;

			for (pass in 0...2) {
				final syncChildren = children.copy();
				var visible = 0;
				var implicitPrimary = 0.0;
				var implicitCross = 0.0;

				items.resize(0);

				for (c in syncChildren)
					commitChild(c);

				for (c in children)
					if (c.isVisible) {
						visible++;

						final lead = c.$primaryStart.margin;
						final trail = c.$primaryEnd.margin;
						final crossLead = c.$crossStart.margin;
						final crossTrail = c.$crossEnd.margin;
						final prefPrimary = $primaryPref;
						final minPrimary = $primaryMin;
						final maxPrimary = $primaryMax;
						final prefCross = $crossPref;
						final minCross = $crossMin;
						final maxCross = $crossMax;
						final cellPref = lead + prefPrimary + trail;
						final crossPrefSize = crossLead + prefCross + crossTrail;

						items.push({
							child: c,
							fillPrimary: c.layout.$primaryFill,
							fillCross: c.layout.$crossFill,
							alignment: resolveAlignment(c.layout.alignment, s.ui.Alignment.AlignLeft, s.ui.Alignment.AlignVCenter, mirror),
							stretchPrimary: c.layout.$primaryStretch,
							lead: lead,
							trail: trail,
							crossLead: crossLead,
							crossTrail: crossTrail,
							prefPrimary: prefPrimary,
							minPrimary: minPrimary,
							maxPrimary: maxPrimary,
							prefCross: prefCross,
							minCross: minCross,
							maxCross: maxCross,
							cellMin: lead + minPrimary + trail,
							cellPref: cellPref,
							cellMax: lead + maxPrimary + trail,
							cellSize: cellPref
						});

						implicitPrimary += cellPref;
						if (implicitCross < crossPrefSize)
							implicitCross = crossPrefSize;
					} else
						commitChild(c);

				if (visible > 1)
					implicitPrimary += (visible - 1) * spacing;

				$primaryReal = $psRef.padding + implicitPrimary + $peRef.padding;
				$crossReal = $csRef.padding + implicitCross + $i{crossEnd}.padding;

				if (visible == 0)
					return;

				final gapCount = visible - 1;
				var availablePrimary = $freePrimaryRef;
				if (gapCount > 0)
					availablePrimary -= gapCount * spacing;
				if (availablePrimary < 0.0)
					availablePrimary = 0.0;

				if (uniformCellSizes)
					layoutUniformCells(items, availablePrimary);
				else
					distributeLinearCells(items, availablePrimary);

				var primaryBase = $primaryBaseStart;
				final crossBase = $crossBase;
				var crossSpace = $freeCrossRef;
				if (crossSpace < 0.0)
					crossSpace = 0.0;

				for (item in items) {
					final c = item.child;
					final contentPrimary = Math.max(0.0, item.cellSize - item.lead - item.trail);
					final targetPrimary = item.fillPrimary ? $targetPrimary : item.prefPrimary;
					var extraPrimary = contentPrimary - targetPrimary;
					if (extraPrimary < 0.0)
						extraPrimary = 0.0;

					final contentCross = Math.max(0.0, crossSpace - item.crossLead - item.crossTrail);
					final targetCross = item.fillCross ? $targetCross : item.prefCross;
					var extraCross = contentCross - targetCross;
					if (extraCross < 0.0)
						extraCross = 0.0;

					c.$primarySize = targetPrimary;
					c.$crossSize = targetCross;

					final primaryCellStart = reverse ? primaryBase - item.cellSize : primaryBase;
					var primaryOffset = 0.0;
					if (item.alignment.matches($primaryAlignEnd))
						primaryOffset = extraPrimary;
					else if (item.alignment.matches($primaryAlignCenter))
						primaryOffset = extraPrimary * 0.5;

					var crossOffset = 0.0;
					if (item.alignment.matches($crossAlignEnd))
						crossOffset = extraCross;
					else if (item.alignment.matches($crossAlignCenter))
						crossOffset = extraCross * 0.5;

					c.$primaryStart.position = primaryCellStart + item.lead + primaryOffset;
					c.$crossStart.position = crossBase + item.crossLead + crossOffset;

					commitChild(c);

					if (reverse)
						primaryBase = primaryCellStart - spacing;
					else
						primaryBase = primaryCellStart + item.cellSize + spacing;
				}
			}
		}
	}
}
