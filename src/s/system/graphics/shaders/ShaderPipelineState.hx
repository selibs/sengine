package s.system.graphics.shaders;

import kha.graphics4.CullMode;
import kha.graphics4.CompareMode;
import kha.graphics4.StencilValue;
import kha.graphics4.StencilAction;
import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;

typedef ShaderPipelineState = {
	var inputLayout:Array<VertexStructure>;
	var vertexShader:String;
	var fragmentShader:String;

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
