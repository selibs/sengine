package s.markup.graphics;

import kha.graphics4.VertexData;
import kha.graphics4.ConstantLocation;
import s.graphics.shaders.Shader;
import s.markup.elements.DrawableElement;

@:allow(s.markup.elements.DrawableElement)
abstract class ElementDrawer<T:DrawableElement> extends Shader {
	var mvpCL:ConstantLocation;
	var rectCL:ConstantLocation;
	var colorCL:ConstantLocation;

	function new(frag:String, vert:String = "element") {
		super({
			inputLayout: [["vertPos" => Float32_2X]],
			vertexShader: vert,
			fragmentShader: frag,
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	override function setup() {
		mvpCL = pipeline.getConstantLocation("mvp");
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
		ctx.setMat3(mvpCL, target.context2D.transform);
		ctx.setFloat4(rectCL, element.left.position, element.top.position, element.width, element.height);
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
