package s.ui.graphics;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.ui.elements.Drawable;

@:allow(s.ui.elements.Drawable)
@:access(s.ui.elements.Drawable)
abstract class TexturedElementDrawer<T:Drawable> extends ElementDrawer<T> {
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

	override function setUniforms(target:s.graphics.RenderTarget, element:T) {
		final ctx = target.context3D;
		ctx.setMat3(mvpCL, element.realTransform * target.context2D.transform);
		ctx.setVec4(colorCL, element.realColor);
	}
}
