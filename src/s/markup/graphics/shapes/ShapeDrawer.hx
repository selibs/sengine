package s.markup.graphics.shapes;

import kha.graphics4.VertexData;
import kha.graphics4.ConstantLocation;
import s.Texture;
import s.math.Mat3;
import s.graphics.shaders.Shader;

@:allow(s.markup.elements.shapes.Shape)
@:access(s.markup.elements.DrawableElement)
abstract class ShapeDrawer<T:s.markup.elements.shapes.Shape> extends DrawableElementDrawer<T> {
	var radiusCL:ConstantLocation;
	var borderWidthCL:ConstantLocation;
	var borderColorCL:ConstantLocation;

	override function setup() {
		super.setup();
		radiusCL = pipeline.getConstantLocation("radius");
		borderWidthCL = pipeline.getConstantLocation("borderWidth");
		borderColorCL = pipeline.getConstantLocation("borderColor");
	}

	override function setUniforms(target:Texture, element:T) {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setFloat(radiusCL, element.realRadius);
		ctx.setFloat(borderWidthCL, element.border.width);
		ctx.setFloat4(borderColorCL, element.border.color.RGBA);
	}
}
