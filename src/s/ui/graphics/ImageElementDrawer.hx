package s.ui.graphics;

import s.ui.elements.ImageElement;
import s.assets.internal.image.Image;

@:allow(s.ui.elements.ImageElement)
class ImageElementDrawer<T:Image = Image> extends TexturedElementDrawer<ImageElement<T>> {
	override function setUniforms(target:s.graphics.RenderTarget, e:ImageElement<T>) {
		super.setUniforms(target, e);
		final ctx = target.context3D;
		ctx.setVec4(rectCL, e.rect);
		ctx.setVec4(clipRectCL, e.clipRect);
		ctx.setTexture(sourceTU, e.source, e.parameters);
	}
}
