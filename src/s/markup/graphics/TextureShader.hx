package s.markup.graphics;

import kha.Shaders;
import kha.graphics4.PipelineState;
import kha.graphics4.BlendingOperation;
import kha.graphics4.VertexStructure;

class TextureShader {
	var pipeline:PipelineState;

	public var blending:BlendingOperation = Add;
	public var vertexShader:String;
	public var fragmentShader:String;

	public function new(vertexShader:String, fragmentShader:String) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
	}

	function compile() {
		var structure = new VertexStructure();
		structure.add("vertexPosition", Float32_3X);
		structure.add("vertexUV", Float32_2X);
		structure.add("vertexColor", UInt8_4X_Normalized);

		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Reflect.field(Shaders, vertexShader);
		pipeline.fragmentShader = Reflect.field(Shaders, fragmentShader);
		pipeline.alphaBlendSource = SourceAlpha;
		pipeline.alphaBlendDestination = InverseSourceAlpha;
		pipeline.blendSource = SourceAlpha;
		pipeline.blendDestination = InverseSourceAlpha;
		pipeline.blendOperation = blending;
		pipeline.compile();
	}
}
