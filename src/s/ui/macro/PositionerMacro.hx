package s.ui.macro;

using s.extensions.StringExt;

class PositionerMacro {
	public static macro function syncPositionerFlow(s:String, e:String) {
		var ds = macro $p{["s", "ui", "Direction", s.capitalize() + "To" + e.capitalize()]};
		var de = macro $p{["s", "ui", "Direction", e.capitalize() + "To" + s.capitalize()]};
		var sRef = macro $i{s};
		var eRef = macro $i{e};
		var ld = (s == "left" || s == "right" ? "width" : "height") + "Dirty";

		return macro {
			final forward = direction & $de == 0;

			var boundsAreDirty = $sRef.offsetDirty || $eRef.offsetDirty;
			var offsetDirty = flowDirty || flowLayoutDirty || boundsAreDirty;
			var base = forward ? $sRef.position + $sRef.padding : $eRef.position - $eRef.padding;

			for (c in children) {
				var flowDirty = offsetDirty;

				var lm, tm, lp, tp;
				if (forward) {
					lm = c.$s.marginDirty;
					tm = c.$e.marginDirty;
					lp = c.$s.positionDirty;
					tp = c.$e.positionDirty;
				} else {
					lm = c.$e.marginDirty;
					tm = c.$s.marginDirty;
					lp = c.$e.positionDirty;
					tp = c.$s.positionDirty;
				}

				flowDirty = flowDirty || c.visibleDirty || c.visible && (lm || tm || lp || tp || c.$ld);

				if (c.visible && (offsetDirty || c.visibleDirty || lm || lp))
					if (forward)
						c.$s.position = base + c.$s.margin;
					else
						c.$e.position = base - c.$e.margin;

				syncChild(c);

				if (c.visible)
					base = forward ? c.$e.position + c.$e.margin + spacing : c.$s.position - c.$s.margin - spacing;
				offsetDirty = flowDirty;
			}
		}
	}
}
