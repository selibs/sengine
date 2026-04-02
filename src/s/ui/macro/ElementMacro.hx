package s.ui.macro;

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
		var ld = macro $i{length + "IsDirty"};
		var noBind = macro $as == null && $ac == null || $as == null && $ae == null || $ac == null && $ae == null;
		var noAnchor = macro $as == null && $ac == null && $ae == null;

		function syncPos()
			return macro {
				$p = $s.position;
				if (position == Relative && parent != null)
					$p -= parent.$start.position;
			}

		function syncLength()
			return macro {
				@:bypassAccessor $l = $e.position - $s.position;
				lengthChanged = true;
			}

		return macro {
			var lengthChanged = false;

			if ($noAnchor && (positionIsDirty || position == Relative && parent != null && parent.$start.positionIsDirty)) {
				$s.self.position = $p;
				if (position == Relative)
					$s.self.position += parent.$start.position;
			}

			if ($as != null && (anchors.$sd || $as.positionIsDirty || $as.paddingIsDirty))
				$s.self.position = $as.position + $as.padding + $s.margin;
			if ($ac != null && (anchors.$cd || $ac.positionIsDirty || $ac.paddingIsDirty))
				$c.self.position = $ac.position + $ac.padding + $c.margin;
			if ($ae != null && (anchors.$ed || $ae.positionIsDirty || $ae.paddingIsDirty))
				$e.self.position = $ae.position - $ae.padding - $e.margin;

			if ($s.positionIsDirty) {
				${syncPos()};
				if ($ae == null && $ac == null) {
					$e.self.position = $s.position + $l;
					$c.self.position = ($s.position + $e.position) * 0.5;
				} else {
					if ($ae != null && $ac == null)
						$c.self.position = ($s.position + $e.position) * 0.5;
					else if ($ae == null && $ac != null)
						$e.self.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				}
			}

			if ($c.positionIsDirty) {
				if ($as == null && $ae == null) {
					var d = $l * 0.5;
					$s.self.position = $c.position - d;
					$e.self.position = $c.position + d;
					${syncPos()};
				} else {
					if ($as != null && $ae == null)
						$e.self.position = $c.position + ($c.position - $s.position);
					else if ($as == null && $ae != null) {
						$s.self.position = $c.position - ($e.position - $c.position);
						${syncPos()};
					}
					${syncLength()};
				}
			}

			if ($e.positionIsDirty) {
				if ($as == null && $ac == null) {
					$s.self.position = $e.position - $l;
					$c.self.position = ($s.position + $e.position) * 0.5;
					${syncPos()};
				} else {
					if ($as != null && $ac == null)
						$c.self.position = ($s.position + $e.position) * 0.5;
					else if ($as == null && $ac != null) {
						$s.self.position = $c.position - ($e.position - $c.position);
						${syncPos()};
					}
					${syncLength()};
				}
			}

			if ($i{pos + "IsDirty"} && $noAnchor) {
				$s.self.position = $p;
				if (position == Relative && parent != null)
					$s.self.position += parent.$start.position;

				if ($as == null && $ac == null && $ae == null) {
					$c.self.position = $s.position + $l * 0.5;
					$e.self.position = $s.position + $l;
				} else if ($as == null && $ac != null && $ae == null) {
					$e.self.position = $c.position + ($c.position - $s.position);
					${syncLength()};
				} else if ($as == null && $ac == null && $ae != null) {
					${syncLength()};
					$c.self.position = $s.position + $l * 0.5;
				}
			}

			if ($ld) {
				if ($ac == null && $ae == null) {
					$e.self.position = $s.position + $l;
					$c.self.position = $s.position + $l * 0.5;
				} else if ($as == null && $ac == null && $ae != null) {
					$s.self.position = $e.position - $l;
					$c.self.position = $e.position - $l * 0.5;
					${syncPos()};
				} else if ($as == null && $ac != null && $ae == null) {
					var d = $l * 0.5;
					$s.self.position = $c.position - d;
					$e.self.position = $c.position + d;
					${syncPos()};
				}
			}

			if (lengthChanged)
				$ld = true;
		}
	}
}
