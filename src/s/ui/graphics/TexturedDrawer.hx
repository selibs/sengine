package s.ui.graphics;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.ui.elements.Textured;

@:allow(s.ui.elements.Drawable)
@:access(s.ui.elements.Drawable)
class TexturedDrawer<T:Textured = Textured> extends ElementDrawer<T> {
	var sourceTU:TextureUnit;

	function new(?frag:String, ?vert:String) {
		super(frag ?? "texture", vert ?? "texture");
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
	}

	override function setUniforms(target:s.graphics.RenderTarget, element:T) {
		final ctx = target.context3D;
		ctx.setMat3(mvpCL, element.realTransform * target.context2D.transform);
		ctx.setVec4(colorCL, element.realColor);
		ctx.setTexture(sourceTU, element.texture, element.parameters);
	}
}
