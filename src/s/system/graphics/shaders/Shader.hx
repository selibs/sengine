package s.system.graphics.shaders;

import kha.Shaders;
import kha.graphics4.VertexData;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;

@:autoBuild(s.system.macro.ShaderMacro.build())
abstract class Shader {
	static var shaders:Array<Shader> = [];

	var state:ShaderPipelineState;
	var pipeline:PipelineState;

	public static var indices2D(default, null):IndexBuffer;
	public static var vertices2D(default, null):VertexBuffer;

	public static function compileShaders() {
		// vertices
		vertices2D = new VertexBuffer(4, ["vertCoord" => Float32_2X], StaticUsage);
		var vert = vertices2D.lock();
		for (i in 0...4) {
			vert[i * 2 + 0] = i == 0 || i == 1 ? -1.0 : 1.0;
			vert[i * 2 + 1] = i == 0 || i == 3 ? -1.0 : 1.0;
		}
		vertices2D.unlock();

		// indices
		indices2D = new IndexBuffer(6, StaticUsage);
		var ind = indices2D.lock();
		ind[0] = 0;
		ind[1] = 1;
		ind[2] = 2;
		ind[3] = 3;
		ind[4] = 2;
		ind[5] = 0;
		indices2D.unlock();

		for (shader in shaders)
			shader.compile();
	}

	function new(state:ShaderPipelineState) {
		this.state = state;
		shaders.push(this);
	}

	function compile() {
		pipeline = new PipelineState();

		pipeline.inputLayout = state.inputLayout;
		pipeline.vertexShader = Reflect.field(Shaders, state.vertexShader + "_vert");
		pipeline.fragmentShader = Reflect.field(Shaders, state.fragmentShader + "_frag");

		pipeline.cullMode = state.cullMode ?? pipeline.cullMode;
		pipeline.depthWrite = state.depthWrite ?? pipeline.depthWrite;
		pipeline.depthMode = state.depthMode ?? pipeline.depthMode;

		pipeline.stencilFrontMode = state.stencilFrontMode ?? pipeline.stencilFrontMode;
		pipeline.stencilFrontBothPass = state.stencilFrontBothPass ?? pipeline.stencilFrontBothPass;
		pipeline.stencilFrontDepthFail = state.stencilFrontDepthFail ?? pipeline.stencilFrontDepthFail;
		pipeline.stencilFrontFail = state.stencilFrontFail ?? pipeline.stencilFrontFail;
		pipeline.stencilBackMode = state.stencilBackMode ?? pipeline.stencilBackMode;
		pipeline.stencilBackBothPass = state.stencilBackBothPass ?? pipeline.stencilBackBothPass;
		pipeline.stencilBackDepthFail = state.stencilBackDepthFail ?? pipeline.stencilBackDepthFail;
		pipeline.stencilBackFail = state.stencilBackFail ?? pipeline.stencilBackFail;
		pipeline.stencilReferenceValue = state.stencilReferenceValue ?? pipeline.stencilReferenceValue;
		pipeline.stencilReadMask = state.stencilReadMask ?? pipeline.stencilReadMask;
		pipeline.stencilWriteMask = state.stencilWriteMask ?? pipeline.stencilWriteMask;

		pipeline.blendSource = state.blendSource ?? pipeline.blendSource;
		pipeline.blendDestination = state.blendDestination ?? pipeline.blendDestination;
		pipeline.blendOperation = state.blendOperation ?? pipeline.blendOperation;
		pipeline.alphaBlendSource = state.alphaBlendSource ?? pipeline.alphaBlendSource;
		pipeline.alphaBlendDestination = state.alphaBlendDestination ?? pipeline.alphaBlendDestination;
		pipeline.alphaBlendOperation = state.alphaBlendOperation ?? pipeline.alphaBlendOperation;

		pipeline.colorWriteMask = state.colorWriteMask ?? true;
		pipeline.colorWriteMaskRed = state.colorWriteMaskRed ?? pipeline.colorWriteMaskRed;
		pipeline.colorWriteMaskGreen = state.colorWriteMaskGreen ?? pipeline.colorWriteMaskGreen;
		pipeline.colorWriteMaskBlue = state.colorWriteMaskBlue ?? pipeline.colorWriteMaskBlue;
		pipeline.colorWriteMaskAlpha = state.colorWriteMaskAlpha ?? pipeline.colorWriteMaskAlpha;
		pipeline.colorWriteMasksRed = state.colorWriteMasksRed ?? pipeline.colorWriteMasksRed;
		pipeline.colorWriteMasksGreen = state.colorWriteMasksGreen ?? pipeline.colorWriteMasksGreen;
		pipeline.colorWriteMasksBlue = state.colorWriteMasksBlue ?? pipeline.colorWriteMasksBlue;
		pipeline.colorWriteMasksAlpha = state.colorWriteMasksAlpha ?? pipeline.colorWriteMasksAlpha;

		pipeline.colorAttachmentCount = state.colorAttachmentCount ?? pipeline.colorAttachmentCount;
		pipeline.colorAttachments = state.colorAttachments ?? pipeline.colorAttachments;

		pipeline.depthStencilAttachment = state.depthStencilAttachment ?? pipeline.depthStencilAttachment;
		pipeline.conservativeRasterization = state.conservativeRasterization ?? pipeline.conservativeRasterization;

		pipeline.compile();

		setup();
	}

	function setup():Void {}
}
