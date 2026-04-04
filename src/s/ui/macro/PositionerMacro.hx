package s.ui.macro;

using s.extensions.StringExt;

class PositionerMacro {
	public static macro function syncPositionerFlow(s:String, e:String) {
		var ds = macro $p{["s", "ui", "Direction", s.capitalize() + "To" + e.capitalize()]};
		var de = macro $p{["s", "ui", "Direction", e.capitalize() + "To" + s.capitalize()]};
		var sRef = macro $i{s};
		var eRef = macro $i{e};

		return macro {
			final forward = direction & $de == 0;

			var boundsAreDirty = $sRef.positionIsDirty || $eRef.positionIsDirty || $sRef.paddingIsDirty || $eRef.paddingIsDirty;
			var offsetIsDirty = flowIsDirty || directionIsDirty || spacingIsDirty || boundsAreDirty;
			var base = forward ? $sRef.position + $sRef.padding : $eRef.position - $eRef.padding;

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

				flowIsDirty = flowIsDirty || c.visibleIsDirty || c.visible && (lm || tm || lp || tp || c.widthIsDirty);

				if (c.visible && (offsetIsDirty || c.visibleIsDirty || lm || lp))
					if (forward)
						c.$s.self.position = base + c.$s.margin;
					else
						c.$e.self.position = base - c.$e.margin;

				syncChild(c);

				if (c.visible)
					base = forward ? c.$e.position + c.$e.margin + spacing : c.$s.position - c.$s.margin - spacing;
				offsetIsDirty = flowIsDirty;
			}
		}
	}
}
