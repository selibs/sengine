package s.markup.graphics;

import s.markup.graphics.stage.SpritePass;
#if (S2D_LIGHTING == 1)
#if (S2D_LIGHTING_DEFERRED == 1)
import s.markup.graphics.stage.lighting.GeometryPass;
#end
import s.markup.graphics.stage.lighting.LightingPass;
#end
import kha.graphics4.VertexStructure;
import s.graphics.RenderTarget;
import s.markup.stage.Stage;

@:allow(s.markup.stage.Stage)
@:access(s.markup.stage.Stage)
@:dox(hide)
class StageRenderer {
	#if (S2D_LIGHTING == 1)
	#if (S2D_LIGHTING_DEFERRED == 1)
	var geometryPass:GeometryPass;
	#end
	var lightingPass:LightingPass;
	#else
	var spritePass:SpritePass;
	#end

	public function new() {
		var structures = [];
		structures.push(new VertexStructure());
		structures[0].add("vertCoord", Float32_2X);

		#if (S2D_SPRITE_INSTANCING == 1)
		structures.push(new VertexStructure());
		structures[1].instanced = true;
		structures[1].add("cropRect", Float32_4X);
		structures.push(new VertexStructure());
		structures[2].instanced = true;
		structures[2].add("model0", Float32_3X);
		structures[2].add("model1", Float32_3X);
		structures[2].add("model2", Float32_3X);
		structures.push(new VertexStructure());
		structures[3].instanced = true;
		structures[3].add("depth", Float32_1X);
		#end

		#if (S2D_LIGHTING == 1)
		#if (S2D_LIGHTING_DEFERRED == 1)
		geometryPass = new GeometryPass(structures);
		#end
		lightingPass = new LightingPass(structures);
		#else
		// spritePass = new SpritePass(structures);
		#end
	}

	function render(target:RenderTarget, stage:Stage) {
		final ctx = target.context2D;
		ctx.end();
		// render to buffer
		#if (S2D_LIGHTING == 1)
		#if (S2D_LIGHTING_DEFERRED == 1)
		geometryPass.render(stage);
		#end
		lightingPass.render(stage);
		#else
		spritePass.render(stage);
		#end
		// render to target
		ctx.begin();
		ctx.style.color = White;
		ctx.drawScaledImage(stage.renderBuffer.tgt, stage.left.position, stage.top.position, stage.width, stage.height);
	}
}
