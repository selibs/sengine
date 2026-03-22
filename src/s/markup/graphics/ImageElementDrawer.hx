package s.markup.graphics;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.markup.elements.ImageElement;

@:allow(s.markup.elements.ImageElement)
class ImageElementDrawer extends ElementDrawer<ImageElement> {
	var sourceTU:TextureUnit;
	var sourceRectCL:ConstantLocation;
	var sourceClipRectCL:ConstantLocation;

	function new() {
		super("image_element", "image_element");
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
		sourceRectCL = pipeline.getConstantLocation("sourceRect");
		sourceClipRectCL = pipeline.getConstantLocation("sourceClipRect");
	}

	override function setUniforms(target:Texture, e:ImageElement) {
		super.setUniforms(target, e);
		final ctx = target.context3D;
		ctx.setVec4(sourceRectCL, e.rect);
		ctx.setVec4(sourceClipRectCL, e.clipRect);
		ctx.setTexture(sourceTU, e.image);
		ctx.setTextureParameters(sourceTU, e.uAddressing, e.vAddressing, e.textureFilter, e.textureFilter, e.mipmapFilter);
	}
}
