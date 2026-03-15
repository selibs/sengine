package s2d.graphics;

import kha.graphics4.ConstantLocation;
import se.Texture;
import se.graphics.shaders.Shader;

@:allow(s2d.elements.DrawableElement)
@:access(s2d.elements.DrawableElement)
abstract class Drawer2D<T:s2d.elements.DrawableElement> extends Shader {
	var modelCL:ConstantLocation;
	var colorCL:ConstantLocation;

	override function setup() {
		modelCL = pipeline.getConstantLocation("model");
		colorCL = pipeline.getConstantLocation("color");
	}

	public function render(target:Texture, element:T) {
		final ctx = target.context3D;
		ctx.setPipeline(pipeline);
		ctx.setIndexBuffer(Shader.indices2D);
		ctx.setVertexBuffer(Shader.vertices2D);
		ctx.setMat3(modelCL, target.context2D.transform);
		ctx.setFloat4(colorCL, element.color);
		draw(target, element);
	}

	abstract function draw(target:Texture, element:T):Void;
}
