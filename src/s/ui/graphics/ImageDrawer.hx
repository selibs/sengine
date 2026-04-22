package s.ui.graphics;

import s.ui.elements.ImageElement;

class ImageDrawer<T:Image> extends TexturedDrawer<ImageElement<T>> {
	var clipRectCL:ConstantLocation;
    
	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
	}

	override function setUniforms(target:s.graphics.RenderTarget, element:T) {
		final ctx = target.context3D;
		ctx.setVec4(rectCL, element.rect);
		ctx.setVec4(clipRectCL, element.clipRect);
	}
}
