package s.markup.graphics;

import kha.graphics4.VertexData;
import kha.graphics4.ConstantLocation;
import s.math.Mat3;
import s.graphics.shaders.Shader;
import s.markup.elements.DrawableElement;

@:allow(s.markup.elements.DrawableElement)
@:access(s.markup.elements.DrawableElement)
abstract class DrawableElementDrawer<T:DrawableElement> extends Shader {
	var projectionCL:ConstantLocation;
	var modelCL:ConstantLocation;
	var rectCL:ConstantLocation;
	var colorCL:ConstantLocation;

	function new(frag:String) {
		super({
			inputLayout: [["vertPos" => Float32_2X]],
			vertexShader: "drawable_element",
			fragmentShader: frag,
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	override function setup() {
		projectionCL = pipeline.getConstantLocation("projection");
		modelCL = pipeline.getConstantLocation("model");
		rectCL = pipeline.getConstantLocation("rect");
		colorCL = pipeline.getConstantLocation("color");
	}

	public function render(target:Texture, element:T) {
		final ctx = target.context3D;
		ctx.setPipeline(pipeline);
		setUniforms(target, element);
		setBuffers(target, element);
		draw(target, element);
	}

	function setUniforms(target:Texture, element:T) {
		final ctx = target.context3D;
		ctx.setMat3(projectionCL, Mat3.orthogonalProjection(0.0, target.width, target.height, 0.0));
		ctx.setMat3(modelCL, target.context2D.transform);
		ctx.setFloat4(rectCL, element.left.position, element.top.position, element.width.real, element.height.real);
		ctx.setFloat4(colorCL, element.color.RGBA);
	}

	function setBuffers(target:Texture, element:T) {
		final ctx = target.context3D;
		ctx.setIndexBuffer(Shader.indices2D);
		ctx.setVertexBuffer(Shader.vertices2D);
	}

	function draw(target:Texture, element:T):Void {
		final ctx = target.context3D;
		ctx.draw();
	}
}
