package s.ui.macro;

class ElementMacro {
	public static macro function syncAxis(start:String, center:String, end:String, pos:String, length:String) {
		var sd = start + "Dirty";
		var cd = center + "Dirty";
		var ed = end + "Dirty";

		var as = macro anchors.$start;
		var ac = macro anchors.$center;
		var ae = macro anchors.$end;

		var s = macro $i{start};
		var c = macro $i{center};
		var e = macro $i{end};

		var p = macro $i{pos};
		var l = macro $i{length};
		var ld = macro $i{length + "Dirty"};
		var noBind = macro $as == null && $ac == null || $as == null && $ae == null || $ac == null && $ae == null;
		var noAnchor = macro $as == null && $ac == null && $ae == null;

		function syncPos()
			return macro {
				$p = $s.position;
				if (parent != null)
					$p -= parent.$start.position;
			}

		function syncLength()
			return macro {
				@:bypassAccessor $l = $e.position - $s.position;
				lengthChanged = true;
			}

		return macro {
			var lengthChanged = false;

			if ($noAnchor && (parent != null && parent.$start.positionDirty))
				$s.position = $p + parent.$start.position;

			if ($as != null && (anchors.$sd || $as.offsetDirty))
				$s.position = $as.position + $as.padding + $s.margin;
			if ($ac != null && (anchors.$cd || $ac.offsetDirty))
				$c.position = $ac.position + $ac.padding + $c.margin;
			if ($ae != null && (anchors.$ed || $ae.offsetDirty))
				$e.position = $ae.position - $ae.padding - $e.margin;

			if ($s.positionDirty) {
				${syncPos()};
				if ($ae == null && $ac == null) {
					$e.position = $s.position + $l;
					$c.position = ($s.position + $e.position) * 0.5;
				} else {
					if ($ae != null && $ac == null)
						$c.position = ($s.position + $e.position) * 0.5;
					else if ($ae == null && $ac != null)
						$e.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				}
			}

			if ($c.positionDirty) {
				if ($as == null && $ae == null) {
					var d = $l * 0.5;
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

			if ($e.positionDirty) {
				if ($as == null && $ac == null) {
					$s.position = $e.position - $l;
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

			if ($i{pos + "Dirty"} && $noAnchor) {
				$s.position = $p;
				if (parent != null)
					$s.position += parent.$start.position;

				if ($as == null && $ac == null && $ae == null) {
					$c.position = $s.position + $l * 0.5;
					$e.position = $s.position + $l;
				} else if ($as == null && $ac != null && $ae == null) {
					$e.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				} else if ($as == null && $ac == null && $ae != null) {
					${syncLength()};
					$c.position = $s.position + $l * 0.5;
				}
			}

			if ($ld) {
				if ($ac == null && $ae == null) {
					$e.position = $s.position + $l;
					$c.position = $s.position + $l * 0.5;
				} else if ($as == null && $ac == null && $ae != null) {
					$s.position = $e.position - $l;
					$c.position = $e.position - $l * 0.5;
					${syncPos()};
				} else if ($as == null && $ac != null && $ae == null) {
					var d = $l * 0.5;
					$s.position = $c.position - d;
					$e.position = $c.position + d;
					${syncPos()};
				}
			}

			if (lengthChanged)
				$ld = true;
		}
	}
}
