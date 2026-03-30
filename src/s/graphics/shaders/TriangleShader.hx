package s.graphics.shaders;

import kha.graphics4.ConstantLocation;

class TriangleShader extends Shader {
	var mvpCL:ConstantLocation;
	var colorCL:ConstantLocation;

	function new() {
		super({
			inputLayout: [Shader.structure2D],
			vertexShader: "triangle2d",
			fragmentShader: "shader2d",
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	override function setup() {
		mvpCL = pipeline.getConstantLocation("mvp");
		colorCL = pipeline.getConstantLocation("color");
	}

	public function render(context:Context2D, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float) {
		var style = context.style;
		var color = style.color;

		var ctx = @:privateAccess context.context;
		ctx.setPipeline(pipeline);
		ctx.setMesh([[[x1, y1, 0.0, 1.0], [x2, y2, 0.5, 0.0], [x3, y3, 1.0, 1.0]]]);
		ctx.setMat3(mvpCL, context.transform);
		ctx.setVec4(colorCL, color.r, color.g, color.b, color.a * style.opacity);
		ctx.draw();
	}
}
