package s.markup.graphics;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.markup.elements.DrawableElement;

@:allow(s.markup.elements.DrawableElement)
abstract class TexturedElementDrawer<T:DrawableElement> extends ElementDrawer<T> {
	var sourceTU:TextureUnit;
	var clipRectCL:ConstantLocation;

	function new(?frag:String, ?vert:String) {
		super(frag ?? "texture", vert ?? "texture");
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
		clipRectCL = pipeline.getConstantLocation("clipRect");
	}

	override function setUniforms(target:Texture, element:T) {
		final ctx = target.context3D;
		ctx.setMat3(mvpCL, target.context2D.transform);
		ctx.setFloat4(colorCL, element.color.RGBA);
	}
}
