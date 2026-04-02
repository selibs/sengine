package s.ui.graphics;

import s.ui.elements.ImageElement;

@:allow(s.ui.elements.ImageElement)
class ImageElementDrawer extends TexturedElementDrawer<ImageElement> {
	override function setUniforms(target:s.graphics.RenderTarget, e:ImageElement) {
		super.setUniforms(target, e);
		final ctx = target.context3D;
		ctx.setVec4(rectCL, e.rect);
		ctx.setVec4(clipRectCL, e.clipRect);
		ctx.setTexture(sourceTU, e.source, e.parameters);
	}
}
