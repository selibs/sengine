package s.ui.layouts;

class BoxLayout extends Element {
	@:attr var spaceH:Float = 0.0;
	@:attr var spaceV:Float = 0.0;

	@:readonly @:alias public var freeWidth:Float = spaceH;
	@:readonly @:alias public var freeHeight:Float = spaceV;

	override function sync() {
		super.sync();

		if (widthIsDirty || left.paddingIsDirty || right.paddingIsDirty)
			spaceH = width - left.padding - right.padding;

		if (heightIsDirty || top.paddingIsDirty || bottom.paddingIsDirty)
			spaceV = height - top.padding - bottom.padding;
	}

	override function syncChild(c:Element) {
		final l = c.layout;

		if (l.alignmentIsDirty) {
			final a = c.anchors;
			a.clear();

			if (l.alignment != Alignment.None) {
				if (l.alignment & Alignment.AlignRight != 0) {
					a.right = right;
				} else if (l.alignment & Alignment.AlignHCenter != 0)
					a.hCenter = hCenter;
				else
					a.left = left;

				if (l.alignment & Alignment.AlignBottom != 0)
					a.bottom = bottom;
				else if (l.alignment & Alignment.AlignVCenter != 0)
					a.vCenter = vCenter;
				else
					a.top = top;
			}
		}

		final lHIsDirty = l.minimumWidthIsDirty || l.maximumWidthIsDirty;
		if (!Math.isNaN(l.preferredWidth) && (l.preferredWidthIsDirty || lHIsDirty))
			c.width = Layout.clampWidth(c, l.preferredWidth);
		else if (l.fillWidth && (l.preferredWidthIsDirty || lHIsDirty || l.fillWidthIsDirty || l.fillWidthFactorIsDirty || spaceHIsDirty))
			c.width = Layout.clampWidth(c, spaceH * l.fillWidthFactor);

		final lVIsDirty = l.minimumHeightIsDirty || l.maximumHeightIsDirty;
		if (!Math.isNaN(l.preferredHeight) && (l.preferredHeightIsDirty || lVIsDirty))
			c.height = Layout.clampHeight(c, l.preferredHeight);
		else if (l.fillHeight
			&& (l.preferredHeightIsDirty || lVIsDirty || l.fillHeightIsDirty || l.fillHeightFactorIsDirty || spaceVIsDirty))
			c.height = Layout.clampHeight(c, spaceV * l.fillHeightFactor);

		super.syncChild(c);
	}
}
