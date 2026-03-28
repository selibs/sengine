package s.graphics.shaders;

import kha.graphics4.ConstantLocation;

abstract class Shader2D extends Shader {
	var mvpCL:ConstantLocation;
	var rectCL:ConstantLocation;
	var colorCL:ConstantLocation;

	function new(frag:String = "shader2d", vert:String = "shader2d") {
		super({
			inputLayout: [Shader.structure2D],
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

	function set(context:Context2D) {
		var style = context.style;
		var color = style.color;
		var ctx = context.context;
		ctx.setPipeline(pipeline);
		ctx.setIndexBuffer(Shader.rectIndices2D);
		ctx.setVertexBuffer(Shader.rectVertices2D);
		ctx.setMat3(mvpCL, context.transform);
		ctx.setVec4(colorCL, color.r, color.g, color.b, color.a * style.opacity);
	}
}
