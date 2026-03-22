package s.markup.graphics.gradients;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.markup.elements.gradients.Gradient;

@:allow(s.markup.elements.gradients.Gradient)
abstract class GradientDrawer<T:Gradient> extends ElementDrawer<T> {
	var startCL:ConstantLocation;
	var endCL:ConstantLocation;
	var gradientTU:TextureUnit;

	function new(fragmentShader:String) {
		super(fragmentShader);
	}

	override function setup() {
		super.setup();
		startCL = pipeline.getConstantLocation("start");
		endCL = pipeline.getConstantLocation("end");
		gradientTU = pipeline.getTextureUnit("gradient");
	}

	override function setUniforms(target:Texture, element:T) {
		super.setUniforms(target, element);
		final l = element.left.position;
		final t = element.top.position;
		final w = element.width;
		final h = element.height;
		final start = element.start;
		final end = element.end;
		final ctx = target.context3D;
		ctx.setVec2(startCL, {x: l + start.x * w, y: t + start.y * h});
		ctx.setVec2(endCL, {x: l + end.x * w, y: t + end.y * h});
		ctx.setTexture(gradientTU, element.gradient);
	}
}
