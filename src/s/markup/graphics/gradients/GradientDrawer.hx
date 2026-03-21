package s.markup.graphics.gradients;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.markup.elements.gradients.Gradient;

@:allow(s.markup.elements.gradients.Gradient)
abstract class GradientDrawer<T:Gradient> extends DrawableElementDrawer<T> {
	var startCL:ConstantLocation;
	var endCL:ConstantLocation;
	var gradientTU:TextureUnit;

	override function setup() {
		super.setup();
		startCL = pipeline.getConstantLocation("start");
		endCL = pipeline.getConstantLocation("end");
		gradientTU = pipeline.getTextureUnit("gradient");
	}

	override function setUniforms(target:Texture, element:T) {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setVec2(startCL, element.realStart);
		ctx.setVec2(endCL, element.realEnd);
		ctx.setTexture(gradientTU, element.gradient);
	}
}
