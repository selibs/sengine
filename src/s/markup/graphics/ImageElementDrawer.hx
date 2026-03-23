package s.markup.graphics;

import s.markup.elements.ImageElement;

@:allow(s.markup.elements.ImageElement)
class ImageElementDrawer extends TexturedElementDrawer<ImageElement> {
	override function setUniforms(target:Texture, e:ImageElement) {
		super.setUniforms(target, e);
		final ctx = target.context3D;
		ctx.setVec4(rectCL, e.rect);
		ctx.setVec4(clipRectCL, e.clipRect);
		ctx.setTexture(sourceTU, e.image, e.parameters);
	}
}
