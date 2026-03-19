package s.markup.macro;

class ElementMacro {
	public static macro function syncAxis(start:String, center:String, end:String, pos:String, length:String) {
		var sd = start + "IsDirty";
		var cd = center + "IsDirty";
		var ed = end + "IsDirty";

		var as = macro anchors.$start;
		var ac = macro anchors.$center;
		var ae = macro anchors.$end;

		var s = macro $i{start};
		var c = macro $i{center};
		var e = macro $i{end};

		var p = macro $i{pos};
		var l = macro $i{length};
		var noBind = macro $as == null && $ac == null || $as == null && $ae == null || $ac == null && $ae == null;
		var noAnchor = macro $as == null && $ac == null && $ae == null;

		function syncPos()
			return macro {
				$p = $s.position;
				if (parent != null)
					$p -= parent.$start.position;
			}

		function syncLength()
			return macro $l.self.real = $e.position - $s.position;

		return macro {
			if ($noBind)
				switch $l.self.unit {
					case s.markup.Length.LengthUnit.Percent:
						$l.self.real = parent == null ? 0.0 : parent.$length.real * 0.01 * $l.self.value;
					case s.markup.Length.LengthUnit.ViewportWidth:
						$l.self.real = target.width * 0.01 * $l.self.value;
					case s.markup.Length.LengthUnit.ViewportHeight:
						$l.self.real = target.height * 0.01 * $l.self.value;
					case s.markup.Length.LengthUnit.ViewportMinimum:
						$l.self.real = Math.min(target.width, target.height) * 0.01 * $l.self.value;
					case s.markup.Length.LengthUnit.ViewportMaximum:
						$l.self.real = Math.max(target.width, target.height) * 0.01 * $l.self.value;
					case _:
				}

			if ($noAnchor && parent != null && parent.$start.positionIsDirty)
				$s.position = parent.$start.position + $p;

			if ($as != null && (anchors.$sd || $as.positionIsDirty || $as.paddingIsDirty))
				$s.position = $as.position + $as.padding + $s.margin;
			if ($ac != null && (anchors.$cd || $ac.positionIsDirty || $ac.paddingIsDirty))
				$c.position = $ac.position + $ac.padding + $c.margin;
			if ($ae != null && (anchors.$ed || $ae.positionIsDirty || $ae.paddingIsDirty))
				$e.position = $ae.position - $ae.padding - $e.margin;

			if ($s.positionIsDirty) {
				${syncPos()};
				if ($ae == null && $ac == null) {
					$e.position = $s.position + $l.real;
					$c.position = ($s.position + $e.position) * 0.5;
				} else {
					if ($ae != null && $ac == null)
						$c.position = ($s.position + $e.position) * 0.5;
					else if ($ae == null && $ac != null)
						$e.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				}
			}

			if ($c.positionIsDirty) {
				if ($as == null && $ae == null) {
					var d = $l.real * 0.5;
					$s.position = $c.position - d;
					$e.position = $c.position + d;
					${syncPos()};
				} else {
					if ($as != null && $ae == null)
						$e.position = $c.position + ($c.position - $s.position);
					else if ($as == null && $ae != null) {
						$s.position = $c.position - ($e.position - $c.position);
						${syncPos()};
					}
					${syncLength()};
				}
			}

			if ($e.positionIsDirty) {
				if ($as == null && $ac == null) {
					$s.position = $e.position - $l.real;
					$c.position = ($s.position + $e.position) * 0.5;
					${syncPos()};
				} else {
					if ($as != null && $ac == null)
						$c.position = ($s.position + $e.position) * 0.5;
					else if ($as == null && $ac != null) {
						$s.position = $c.position - ($e.position - $c.position);
						${syncPos()};
					}
					${syncLength()};
				}
			}

			if ($i{pos + "IsDirty"} && $noAnchor) {
				$s.position = $p;
				if (parent != null)
					$s.position += parent.$start.position;

				if ($as == null && $ac == null && $ae == null) {
					$c.position = $s.position + $l.real * 0.5;
					$e.position = $s.position + $l.real;
				} else if ($as == null && $ac != null && $ae == null) {
					$e.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				} else if ($as == null && $ac == null && $ae != null) {
					${syncLength()};
					$c.position = $s.position + $l.real * 0.5;
				}
			}

			if ($i{length + "IsDirty"} || $l.realIsDirty) {
				if ($ac == null && $ae == null) {
					$e.position = $s.position + $l.real;
					$c.position = $s.position + $l.real * 0.5;
				} else if ($as == null && $ac == null && $ae != null) {
					$s.position = $e.position - $l.real;
					$c.position = $e.position - $l.real * 0.5;
					${syncPos()};
				} else if ($as == null && $ac != null && $ae == null) {
					var d = $l.real * 0.5;
					$s.position = $c.position - d;
					$e.position = $c.position + d;
					${syncPos()};
				}
			}
		}
	}
}
