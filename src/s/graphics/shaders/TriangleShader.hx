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
		var vert = Shader.triVertices2D.lock();
		vert[0] = x1;
		vert[1] = y1;
		vert[2] = 0.0;
		vert[3] = 1.0;
		vert[4] = x2;
		vert[5] = y2;
		vert[6] = 0.5;
		vert[7] = 0.0;
		vert[8] = x3;
		vert[9] = y3;
		vert[10] = 1.0;
		vert[11] = 1.0;
		Shader.triVertices2D.unlock();

		var style = context.style;
		var color = style.color;

		var ctx = @:privateAccess context.context;
		ctx.setPipeline(pipeline);
		ctx.setIndexBuffer(Shader.triIndices2D);
		ctx.setVertexBuffer(Shader.triVertices2D);
		ctx.setMat3(mvpCL, context.transform);
		ctx.setVec4(colorCL, color.r, color.g, color.b, color.a * style.opacity);
		ctx.draw();
	}
}
