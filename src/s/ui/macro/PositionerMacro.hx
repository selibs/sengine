package s.ui.macro;

import haxe.macro.Expr;

using s.extensions.StringExt;

class PositionerMacro {
	public static macro function updatePositionFlow(d:String) {
		var l:String, s:String, c:String, e:String;
		var cl:String, cs:String, cc:String, ce:String;

		switch d {
			case "horizontal":
				l = "width";
				s = "left";
				c = "hCenter";
				e = "right";
				cl = "height";
				cs = "top";
				cc = "vCenter";
				ce = "bottom";
			case "vertical":
				l = "height";
				s = "top";
				c = "vCenter";
				e = "bottom";
				cl = "width";
				cs = "left";
				cc = "hCenter";
				ce = "right";
			default:
				throw "Invalid axis: " + d;
		}

		var sRef = macro $i{s};
		var cRef = macro $i{c};
		var eRef = macro $i{e};
		var rlRef = macro $i{'real${l.capitalize()}'};
		var StoERef = macro $i{'${s.capitalize()}To${e.capitalize()}'};
		var aERef = macro $i{'Align${e.capitalize()}'};
		var aCRef = macro $i{'Align${c.capitalize()}'};

		var csRef = macro $i{cs};
		var ccRef = macro $i{cc};
		var ceRef = macro $i{ce};
		var crlRef = macro $i{'real${cl.capitalize()}'};
		var caERef = macro $i{'Align${ce.capitalize()}'};
		var caCRef = macro $i{'Align${cc.capitalize()}'};

		function crossAlign()
			return macro {
				if (alignment.matches($caERef))
					c.$ce.position = $ceRef.position - $ceRef.padding - c.$ce.margin;
				else if (alignment.matches($caCRef))
					c.$cc.position = $ccRef.position + $ccRef.padding + c.$cc.margin;
				else
					c.$cs.position = $csRef.position + $csRef.padding + c.$cs.margin;
			}

		return macro {
			$rlRef = 0.0;
			$crlRef = 0.0;
			var visible = 0;

			for (c in children)
				if (c.isVisible) {
					$rlRef += c.$l;
					if ($crlRef < c.$cl)
						$crlRef = c.$cl;
					visible++;
				}
			if (visible > 1)
				$rlRef += (visible - 1) * spacing;

			var base = 0.0;
			// Align*End*
			if (alignment.matches($aERef))
				base = $eRef.position - $eRef.padding - $rlRef;
			// Align*Center*
			else if (alignment.matches($aCRef))
				base = $cRef.position + $cRef.padding - $rlRef * 0.5;
			// fallback: Align*Start*
			else
				base = $sRef.position + $sRef.padding;

			if (direction.matches($StoERef)) {
				var i = 0;
				while (i < children.count) {
					var c = children[i++];
					if (c.isVisible) {
						c.$s.position = base + c.$s.margin;
						${crossAlign()};
						updateChild(c);
						base = c.$e.position + c.$e.margin + spacing;
					}
				}
			} else {
				base += $rlRef;
				var i = children.count;
				while (i > 0) {
					var c = children[--i];
					if (c.isVisible) {
						c.$e.position = base - c.$e.margin;
						${crossAlign()};
						updateChild(c);
						base = c.$s.position - c.$s.margin - spacing;
					}
				}
			}
		}
	}
}
