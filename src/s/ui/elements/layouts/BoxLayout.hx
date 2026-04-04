package s.ui.elements.layouts;

class BoxLayout extends ContainerElement {
	override function syncChild(c:Element) {
		final l = c.layout;

		if (l.alignmentIsDirty)
			Layout.align(c, left, hCenter, right, top, vCenter, bottom);

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
