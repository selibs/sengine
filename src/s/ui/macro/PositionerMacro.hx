package s.ui.macro;

using s.extensions.StringExt;

class PositionerMacro {
	public static macro function updatePositionerFlow(s:String, e:String) {
		var ds = macro $p{["s", "ui", "Direction", s.capitalize() + "To" + e.capitalize()]};
		var de = macro $p{["s", "ui", "Direction", e.capitalize() + "To" + s.capitalize()]};
		var sRef = macro $i{s};
		var eRef = macro $i{e};
		var ld = (s == "left" || s == "right" ? "width" : "height") + "Dirty";
		var pd = s == "left" || s == "right" ? "xDirty" : "yDirty";

		return macro {
			if (flowLayoutDirty)
				flowDirty = true;

			final forward = direction & $de == 0;

			var boundsAreDirty = $sRef.offsetDirty || $eRef.offsetDirty;
			var offsetDirty = children.dirty || flowDirty || flowLayoutDirty || boundsAreDirty;
			var base = forward ? $sRef.position + $sRef.padding : $eRef.position - $eRef.padding;
			var items = children.copy();

			for (c in items) {
				var childDirty = offsetDirty;

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

				childDirty = childDirty || c.dirty || c.isVisibleDirty || c.isVisible && (lm || tm || lp || tp || c.$ld || c.$pd);

				if (c.isVisible && childDirty)
					if (forward)
						c.$s.position = base + c.$s.margin;
					else
						c.$e.position = base - c.$e.margin;

				updateChild(c);

				if (c.isVisible)
					base = forward ? c.$e.position + c.$e.margin + spacing : c.$s.position - c.$s.margin - spacing;
				offsetDirty = childDirty;
			}
		}
	}
}
