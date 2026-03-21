package s.graphics.shaders;

import kha.Shaders;
import kha.graphics4.VertexData;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.CullMode;
import kha.graphics4.CompareMode;
import kha.graphics4.StencilValue;
import kha.graphics4.StencilAction;
import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;

@:autoBuild(s.macro.ShaderMacro.build())
abstract class Shader {
	static var shaders:Array<Shader> = [];

	var state:ShaderPipelineState;
	var pipeline:PipelineState;

	public static var indices2D(default, null):IndexBuffer;
	public static var vertices2D(default, null):VertexBuffer;

	public static function compileShaders() {
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
		// vertices
		vertices2D = new VertexBuffer(4, ["vertPos" => Float32_2X], StaticUsage);
		var vert = vertices2D.lock();
		for (i in 0...4) {
			vert[i * 2 + 0] = i == 0 || i == 1 ? -1.0 : 1.0;
			vert[i * 2 + 1] = i == 0 || i == 3 ? -1.0 : 1.0;
		}
		vertices2D.unlock();

		for (shader in shaders)
			shader.compile();
	}

	function new(state:ShaderPipelineState) {
		this.state = state;
		shaders.push(this);
	}

	function compile() {
		pipeline = new PipelineState();

		if (state.inputLayout == null)
			throw "Input layout can not be null!";
		pipeline.inputLayout = state.inputLayout;

		if (state.vertexShader == null)
			throw "Vertex shader can not be null!";
		pipeline.vertexShader = Reflect.field(Shaders, state.vertexShader + "_vert");

		if (state.fragmentShader == null)
			throw "Fragment layout can not be null!";
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

typedef ShaderPipelineState = {
	var ?inputLayout:Array<VertexStructure>;
	var ?vertexShader:String;
	var ?fragmentShader:String;
	var ?cullMode:CullMode;
	var ?depthWrite:Bool;
	var ?depthMode:CompareMode;
	var ?stencilFrontMode:CompareMode;
	var ?stencilFrontBothPass:StencilAction;
	var ?stencilFrontDepthFail:StencilAction;
	var ?stencilFrontFail:StencilAction;
	var ?stencilBackMode:CompareMode;
	var ?stencilBackBothPass:StencilAction;
	var ?stencilBackDepthFail:StencilAction;
	var ?stencilBackFail:StencilAction;
	var ?stencilReferenceValue:StencilValue;
	var ?stencilReadMask:Int;
	var ?stencilWriteMask:Int;
	var ?blendSource:BlendingFactor;
	var ?blendDestination:BlendingFactor;
	var ?blendOperation:BlendingOperation;
	var ?alphaBlendSource:BlendingFactor;
	var ?alphaBlendDestination:BlendingFactor;
	var ?alphaBlendOperation:BlendingOperation;
	var ?colorWriteMask:Bool;
	var ?colorWriteMaskRed:Bool;
	var ?colorWriteMaskGreen:Bool;
	var ?colorWriteMaskBlue:Bool;
	var ?colorWriteMaskAlpha:Bool;
	var ?colorWriteMasksRed:Array<Bool>;
	var ?colorWriteMasksGreen:Array<Bool>;
	var ?colorWriteMasksBlue:Array<Bool>;
	var ?colorWriteMasksAlpha:Array<Bool>;
	var ?colorAttachmentCount:Int;
	var ?colorAttachments:Array<TextureFormat>;
	var ?depthStencilAttachment:DepthStencilFormat;
	var ?conservativeRasterization:Bool;
}
