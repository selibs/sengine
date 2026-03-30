package s.graphics.shaders;

import kha.graphics4.ConstantLocation;
import s.graphics.FontStyle;
import s.graphics.RenderTarget;

class TextShader extends TexturedShader {
	var italicSlantCL:ConstantLocation;
	var sdfRangeCL:ConstantLocation;
	var sourceInvSizeCL:ConstantLocation;
	var outlineColorCL:ConstantLocation;
	var outlineWidthCL:ConstantLocation;
	var softnessCL:ConstantLocation;
	var weightCL:ConstantLocation;

	function new() {
		super("text2d", "text2d");
	}

	override function setup() {
		super.setup();
		italicSlantCL = pipeline.getConstantLocation("italicSlant");
		sdfRangeCL = pipeline.getConstantLocation("sdfRange");
		sourceInvSizeCL = pipeline.getConstantLocation("sourceInvSize");
		outlineColorCL = pipeline.getConstantLocation("outlineColor");
		outlineWidthCL = pipeline.getConstantLocation("outlineWidth");
		softnessCL = pipeline.getConstantLocation("softness");
		weightCL = pipeline.getConstantLocation("weight");
	}

	public function render(context:Context2D, chars:Array<FontChar>) {
		super.set(context);

		final ctx = context.context;
		final style = context.style;
		final font = style.font;
		final atlas = font.getAtlas();
		final outlineColor = font.outlineColor;

		ctx.setTexture(sourceTU, atlas.getTexture(), Clamp, Clamp, LinearFilter, LinearFilter, NoMipFilter);
		ctx.setFloat(italicSlantCL, font.italicSlant);
		ctx.setFloat(sdfRangeCL, atlas.sdfRange);
		ctx.setVec2(sourceInvSizeCL, 1.0 / atlas.width, 1.0 / atlas.height);
		ctx.setVec4(outlineColorCL, outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * style.opacity);
		ctx.setFloat(outlineWidthCL, font.outlineWidth);
		ctx.setFloat(softnessCL, font.softness);
		ctx.setFloat(weightCL, font.sdfWeight);

		for (c in chars) {
			ctx.setVec4(rectCL, c.pos.x, c.pos.y, c.pos.width, c.pos.height);
			ctx.setVec4(clipRectCL, c.uv);
			ctx.draw();
		}
	}
}
