package s.markup.graphics;

import s.markup.elements.ImageElement;

@:allow(s.markup.elements.ImageElement)
class ImageElementDrawer extends TexturedElementDrawer<ImageElement> {
	override function setUniforms(target:Texture, e:ImageElement) {
		super.setUniforms(target, e);
		final ctx = target.context3D;
		ctx.setVec4(sourceRectCL, e.rect);
		ctx.setVec4(sourceClipRectCL, e.clipRect);
		ctx.setTexture(sourceTU, e.image, e.parameters);
	}
}
