package s2d.graphics.stage;

#if (S2D_LIGHTING != 1)
import kha.Shaders;
import kha.graphics4.VertexStructure;
import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s2d.stage.Stage;

@:dox(hide)
@:access(s2d.stage.Stage)
@:allow(s2d.graphics.StageRenderer)
class SpritePass extends StageRenderPass {
	var viewProjectionCL:ConstantLocation;
	var textureMapTU:TextureUnit;
	#if (S2D_SPRITE_INSTANCING != 1)
	var depthCL:ConstantLocation;
	var modelCL:ConstantLocation;
	var cropRectCL:ConstantLocation;
	#end

	public function new(inputLayout:Array<VertexStructure>) {
		super({
			inputLayout: inputLayout,
			vertexShader: Reflect.field(Shaders, "sprite_vert"),
			fragmentShader: Reflect.field(Shaders, "sprite_frag"),
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	function setup() {
		viewProjectionCL = pipeline.getConstantLocation("viewProjection");
		textureMapTU = pipeline.getTextureUnit("textureMap");
		#if (S2D_SPRITE_INSTANCING != 1)
		depthCL = pipeline.getConstantLocation("depth");
		modelCL = pipeline.getConstantLocation("model");
		cropRectCL = pipeline.getConstantLocation("cropRect");
		#end
	}

	function render(stage:Stage) @:privateAccess {
		final ctx = stage.renderBuffer.tgt.context3D;
		ctx.begin();
		ctx.clear(stage.color);
		ctx.setPipeline(pipeline);
		ctx.setIndexBuffer(Drawers.indices2D);
		#if (S2D_SPRITE_INSTANCING != 1)
		ctx.setVertexBuffer(Drawers.vertices2D);
		#end
		ctx.setMat3(viewProjectionCL, stage.viewProjection);
		for (layer in stage.layers) {
			#if (S2D_SPRITE_INSTANCING == 1)
			for (material in layer.materials) {
				ctx.setVertexBuffers(material.vertices);
				ctx.setTexture(textureMapTU, material.textureMap);
				ctx.drawInstanced(material.sprites.length);
			}
			#else
			for (sprite in layer.sprites) {
				ctx.setFloat(depthCL, sprite.z);
				ctx.setMat3(modelCL, sprite.transform);
				ctx.setVec4(cropRectCL, sprite.cropRect);
				ctx.setTexture(textureMapTU, sprite.material.textureMap);
				ctx.draw();
			}
			#end
		}
		ctx.end();
	}
}
#end
