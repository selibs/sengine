package s.markup.graphics;

import kha.graphics4.ConstantLocation;
import s.system.Texture;
import s.system.graphics.shaders.Shader;

@:allow(s.markup.elements.DrawableElement)
@:access(s.markup.elements.DrawableElement)
abstract class Drawer2D<T:s.markup.elements.DrawableElement> extends Shader {
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
