package s.ui.graphics.shapes;

import kha.graphics4.ConstantLocation;
import s.graphics.RenderTarget;

@:allow(s.ui.shapes.Shape)
abstract class ShapeDrawer<T:s.ui.shapes.Shape> extends ElementDrawer<T> {
	var radiusCL:ConstantLocation;
	var borderWidthCL:ConstantLocation;
	var borderColorCL:ConstantLocation;

	public function new(fragmentShader:String) {
		super(fragmentShader);
	}

	override function setup() {
		super.setup();
		radiusCL = pipeline.getConstantLocation("radius");
		borderWidthCL = pipeline.getConstantLocation("borderWidth");
		borderColorCL = pipeline.getConstantLocation("borderColor");
	}

	override function setUniforms(target:RenderTarget, element:T) {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setFloat(radiusCL, element.realRadius);
		ctx.setFloat(borderWidthCL, element.border.width);
		ctx.setVec4(borderColorCL, element.border.color.RGBA);
	}
}
