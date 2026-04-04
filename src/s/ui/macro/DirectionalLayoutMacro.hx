package s.ui.macro;

using s.extensions.StringExt;

class DirectionalLayoutMacro {
	public static macro function syncLayoutFlow(horizontal:Bool) {
		var s, e, cs, cm, ce, l, cl, align, clamp, cclamp, cspace;

		if (horizontal) {
			s = "left";
			e = "right";
			cs = "top";
			cm = "vCenter";
			ce = "bottom";
			l = "width";
			cl = "height";
			align = "alignV";
			clamp = "clampWidth";
			cclamp = "clampHeight";
			cspace = "spaceV";
		} else {
			s = "top";
			e = "bottom";
			cs = "left";
			cm = "hCenter";
			ce = "right";
			l = "height";
			cl = "width";
			align = "alignH";
			clamp = "clampHeight";
			cclamp = "clampWidth";
			cspace = "spaceH";
		}

		var ds = macro $p{["s", "ui", "Direction", s.capitalize() + "To" + e.capitalize()]};
		var de = macro $p{["s", "ui", "Direction", e.capitalize() + "To" + s.capitalize()]};
		var ld = l + "IsDirty";
		var cspaced = cspace + "IsDirty";

		var L = l.capitalize();
		var CL = cl.capitalize();
		var fl = "fill" + L;
		var flf = fl + "Factor";
		var minl = "minimum" + L;
		var maxl = "maximum" + L;
		var prel = "preferred" + L;
		var fld = fl + "IsDirty";
		var flfd = flf + "IsDirty";
		var minld = minl + "IsDirty";
		var maxld = maxl + "IsDirty";
		var preld = prel + "IsDirty";

		var cfl = "fill" + CL;
		var cflf = cfl + "Factor";
		var mincl = "minimum" + CL;
		var maxcl = "maximum" + CL;
		var precl = "preferred" + CL;
		var cfld = cfl + "IsDirty";
		var cflfd = cflf + "IsDirty";
		var mincld = mincl + "IsDirty";
		var maxcld = maxcl + "IsDirty";
		var precld = precl + "IsDirty";

		var sRef = macro $i{s};
		var eRef = macro $i{e};
		var csRef = macro $i{cs};
		var cmRef = macro $i{cm};
		var ceRef = macro $i{ce};
		var ldRef = macro $i{ld};
		var cspaceRef = macro $i{cspace};
		var cspacedRef = macro $i{cspaced};

		return macro {
			final forward = direction & $de == 0;

			var boundsAreDirty = $sRef.positionIsDirty || $eRef.positionIsDirty || $sRef.paddingIsDirty || $eRef.paddingIsDirty;
			var crossBoundsAreDirty = $csRef.positionIsDirty || $ceRef.positionIsDirty || $csRef.paddingIsDirty || $ceRef.paddingIsDirty;

			var start = forward ? $sRef.position + $sRef.padding : $eRef.position - $eRef.padding;
			var limit = forward ? $eRef.position - $eRef.padding : $sRef.position + $sRef.padding;
			var available = forward ? limit - start : start - limit;
			if (available < 0)
				available = 0;

			var visibleCount = 0;
			var fixed = 0.0;
			var margins = 0.0;
			var fillFactorSum = 0.0;
			var sizeChanged = false;

			for (c in children) {
				if (!c.visible) {
					if (c.visibleIsDirty)
						sizeChanged = true;
					continue;
				}

				var l = c.layout;

				if (l.alignmentIsDirty)
					s.ui.Layout.$align(c, $csRef, $cmRef, $ceRef);

				visibleCount++;
				margins += c.$s.margin + c.$e.margin;

				var primaryMinMaxDirty = l.$minld || l.$maxld;
				var crossMinMaxDirty = l.$mincld || l.$maxcld;

				if (!Math.isNaN(l.$precl) && (l.$precld || crossMinMaxDirty)) {
					var size = s.ui.Layout.$cclamp(c, l.$precl) - (c.$cs.margin + c.$ce.margin);
					if (c.$cl != size) {
						c.$cl = size;
						sizeChanged = true;
					}
				} else if (l.$cfl
					&& (l.$precld || crossMinMaxDirty || l.$cfld || l.$cflfd || $cspacedRef || crossBoundsAreDirty)) {
					var size = s.ui.Layout.$cclamp(c, $cspaceRef * l.$cflf) - (c.$cs.margin + c.$ce.margin);
					if (c.$cl != size) {
						c.$cl = size;
						sizeChanged = true;
					}
				} else if (crossMinMaxDirty) {
					var size = s.ui.Layout.$cclamp(c, c.$cl) - (c.$cs.margin + c.$ce.margin);
					if (c.$cl != size) {
						c.$cl = size;
						sizeChanged = true;
					}
				}

				if (!Math.isNaN(l.$prel) && (l.$preld || primaryMinMaxDirty)) {
					var size = s.ui.Layout.$clamp(c, l.$prel) - (c.$s.margin + c.$e.margin);
					if (c.$l != size) {
						c.$l = size;
						sizeChanged = true;
					}
					fixed += c.$l;
				} else if (l.$fl) {
					fillFactorSum += l.$flf;
				} else {
					if (primaryMinMaxDirty) {
						var size = s.ui.Layout.$clamp(c, c.$l) - (c.$s.margin + c.$e.margin);
						if (c.$l != size) {
							c.$l = size;
							sizeChanged = true;
						}
					}
					fixed += c.$l;
				}
			}

			var spacingTotal = visibleCount > 1 ? spacing * (visibleCount - 1) : 0.0;
			var remaining = available - margins - spacingTotal - fixed;
			if (remaining < 0)
				remaining = 0;

			if (fillFactorSum > 0)
				for (c in children) {
					if (!c.visible)
						continue;
					var l = c.layout;
					if (l.$fl) {
						var size = remaining * l.$flf / fillFactorSum;
						size = s.ui.Layout.$clamp(c, size) - (c.$s.margin + c.$e.margin);
						if (c.$l != size) {
							c.$l = size;
							sizeChanged = true;
						}
					}
				}

			var gap = spacing;
			if (fillFactorSum == 0 && remaining > 0 && visibleCount > 1)
				gap += remaining / (visibleCount - 1);

			var offsetIsDirty = flowIsDirty || directionIsDirty || spacingIsDirty || boundsAreDirty || sizeChanged;
			var base = start;

			for (c in children) {
				var flowIsDirty = offsetIsDirty;

				var lm, tm, lp, tp;
				if (forward) {
					lm = c.$s.marginIsDirty;
					tm = c.$e.marginIsDirty;
					lp = c.$s.positionIsDirty;
					tp = c.$e.positionIsDirty;
				} else {
					lm = c.$e.marginIsDirty;
					tm = c.$s.marginIsDirty;
					lp = c.$e.positionIsDirty;
					tp = c.$s.positionIsDirty;
				}

				flowIsDirty = flowIsDirty || c.visibleIsDirty || c.visible && (lm || tm || lp || tp || c.$ld);

				if (c.visible && (offsetIsDirty || c.visibleIsDirty || lm || lp))
					if (forward)
						c.$s.self.position = base + c.$s.margin;
					else
						c.$e.self.position = base - c.$e.margin;

				syncChild(c);

				if (c.visible)
					base = forward ? c.$e.position + c.$e.margin + gap : c.$s.position - c.$s.margin - gap;
				offsetIsDirty = flowIsDirty;
			}
		}
	}
}
