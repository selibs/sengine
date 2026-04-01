package s.graphics.shaders;

import kha.graphics4.ConstantLocation;
import s.graphics.FontStyle;
import s.graphics.RenderTarget;

class TextShader extends TexturedShader {
	var sdfRangeCL:ConstantLocation;
	var sourceInvSizeCL:ConstantLocation;
	var outlineColorCL:ConstantLocation;
	var outlineWidthCL:ConstantLocation;
	var softnessCL:ConstantLocation;
	var weightCL:ConstantLocation;

	function new() {
		super("text2d", "shader2d");
	}

	override function setup() {
		super.setup();
		sdfRangeCL = pipeline.getConstantLocation("sdfRange");
		sourceInvSizeCL = pipeline.getConstantLocation("sourceInvSize");
		outlineColorCL = pipeline.getConstantLocation("outlineColor");
		outlineWidthCL = pipeline.getConstantLocation("outlineWidth");
		softnessCL = pipeline.getConstantLocation("softness");
		weightCL = pipeline.getConstantLocation("weight");
	}

	inline function spacing(font:FontStyle, char:Int):Float {
		var spacing = font.letterSpacing;
		if (char == " ".code || char == "\t".code)
			spacing += font.wordSpacing;
		return spacing;
	}

	public function render(context:Context2D, chars:Array<FontChar>) {
		if (chars == null || chars.length == 0)
			return;

		super.set(context);

		final ctx = context.context;
		final style = context.style;
		final font = style.font;
		final atlas = font.getAtlas();
		final outlineColor = font.outlineColor;

		ctx.setTexture(sourceTU, atlas.getTexture(), Clamp, Clamp, LinearFilter, LinearFilter, NoMipFilter);
		ctx.setFloat(sdfRangeCL, atlas.sdfRange);
		ctx.setVec2(sourceInvSizeCL, 1.0 / atlas.width, 1.0 / atlas.height);
		ctx.setVec4(outlineColorCL, outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * style.opacity);
		ctx.setFloat(outlineWidthCL, font.outlineWidth);
		ctx.setFloat(softnessCL, font.softness);
		ctx.setFloat(weightCL, font.sdfWeight);

		var drew = false;
		for (c in chars) {
			var h = c.pos.height;
			if (h == 0)
				continue;

			var yTop = c.pos.y;
			var yBottom = c.pos.y + h;
			var yoff = font.snapToPixel ? Math.round(c.yoff) : c.yoff;
			var slantTop = -font.italicSlant * yoff;
			var slantBottom = -font.italicSlant * (yoff + h);
			var xLeftTop = c.pos.x + slantTop;
			var xRightTop = c.pos.x + c.pos.width + slantTop;
			var xLeftBottom = c.pos.x + slantBottom;
			var xRightBottom = c.pos.x + c.pos.width + slantBottom;

			ctx.streamQuad(
				xLeftBottom, yBottom, c.uv.x, c.uv.y + c.uv.height,
				xLeftTop, yTop, c.uv.x, c.uv.y,
				xRightTop, yTop, c.uv.x + c.uv.width, c.uv.y,
				xRightBottom, yBottom, c.uv.x + c.uv.width, c.uv.y + c.uv.height
			);
			drew = true;
		}
		if (drew)
			ctx.draw();
	}

	public function renderCharacters(context:Context2D, text:Array<Int>, start:Int, length:Int, x:Float, y:Float) {
		if (text == null || length <= 0)
			return;

		super.set(context);

		final ctx = context.context;
		final style = context.style;
		final font = style.font;
		final atlas = font.getAtlas();
		final outlineColor = font.outlineColor;

		ctx.setTexture(sourceTU, atlas.getTexture(), Clamp, Clamp, LinearFilter, LinearFilter, NoMipFilter);
		ctx.setFloat(sdfRangeCL, atlas.sdfRange);
		ctx.setVec2(sourceInvSizeCL, 1.0 / atlas.width, 1.0 / atlas.height);
		ctx.setVec4(outlineColorCL, outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * style.opacity);
		ctx.setFloat(outlineWidthCL, font.outlineWidth);
		ctx.setFloat(softnessCL, font.softness);
		ctx.setFloat(weightCL, font.sdfWeight);

		final scale = font.pixelSize / atlas.size;
		final invW = 1.0 / atlas.width;
		final invH = 1.0 / atlas.height;
		final end = Std.int(Math.min(start + length, text.length));
		final snap = font.snapToPixel;

		var offset = x;
		var drew = false;

		for (i in start...end) {
			final code = text[i];
			final g = atlas.getGlyph(code);
			final atlasW = g.x1 - g.x0;
			final atlasH = g.y1 - g.y0;
			final w = atlasW / s.assets.font.Font.sdfOversample * scale;
			final h = atlasH / s.assets.font.Font.sdfOversample * scale;
			final xoff = g.xoff * scale;
			final yoff = g.yoff * scale;
			final advance = g.xadvance + spacing(font, code);

			if (w == 0 || h == 0) {
				offset += advance;
				continue;
			}

			final yoffUsed = snap ? Math.round(yoff) : yoff;
			final yTop = y + yoffUsed;
			final yBottom = yTop + h;
			final xLeft = offset + xoff;
			final xRight = xLeft + w;
			final slantTop = -font.italicSlant * yoffUsed;
			final slantBottom = -font.italicSlant * (yoffUsed + h);

			final u0 = g.x0 * invW;
			final v0 = g.y0 * invH;
			final u1 = g.x1 * invW;
			final v1 = g.y1 * invH;

			ctx.streamQuad(
				xLeft + slantBottom, yBottom, u0, v1,
				xLeft + slantTop, yTop, u0, v0,
				xRight + slantTop, yTop, u1, v0,
				xRight + slantBottom, yBottom, u1, v1
			);
			drew = true;
			offset += advance;
		}

		if (drew)
			ctx.draw();
	}

	public function renderString(context:Context2D, text:String, x:Float, y:Float) {
		if (text == null || text.length == 0)
			return;

		super.set(context);

		final ctx = context.context;
		final style = context.style;
		final font = style.font;
		final atlas = font.getAtlas();
		final outlineColor = font.outlineColor;

		ctx.setTexture(sourceTU, atlas.getTexture(), Clamp, Clamp, LinearFilter, LinearFilter, NoMipFilter);
		ctx.setFloat(sdfRangeCL, atlas.sdfRange);
		ctx.setVec2(sourceInvSizeCL, 1.0 / atlas.width, 1.0 / atlas.height);
		ctx.setVec4(outlineColorCL, outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * style.opacity);
		ctx.setFloat(outlineWidthCL, font.outlineWidth);
		ctx.setFloat(softnessCL, font.softness);
		ctx.setFloat(weightCL, font.sdfWeight);

		final scale = font.pixelSize / atlas.size;
		final invW = 1.0 / atlas.width;
		final invH = 1.0 / atlas.height;
		final snap = font.snapToPixel;

		var offset = x;
		var drew = false;

		for (i in 0...text.length) {
			final code = text.charCodeAt(i);
			final g = atlas.getGlyph(code);
			final atlasW = g.x1 - g.x0;
			final atlasH = g.y1 - g.y0;
			final w = atlasW / s.assets.font.Font.sdfOversample * scale;
			final h = atlasH / s.assets.font.Font.sdfOversample * scale;
			final xoff = g.xoff * scale;
			final yoff = g.yoff * scale;
			final advance = g.xadvance + spacing(font, code);

			if (w == 0 || h == 0) {
				offset += advance;
				continue;
			}

			final yoffUsed = snap ? Math.round(yoff) : yoff;
			final yTop = y + yoffUsed;
			final yBottom = yTop + h;
			final xLeft = offset + xoff;
			final xRight = xLeft + w;
			final slantTop = -font.italicSlant * yoffUsed;
			final slantBottom = -font.italicSlant * (yoffUsed + h);

			final u0 = g.x0 * invW;
			final v0 = g.y0 * invH;
			final u1 = g.x1 * invW;
			final v1 = g.y1 * invH;

			ctx.streamQuad(
				xLeft + slantBottom, yBottom, u0, v1,
				xLeft + slantTop, yTop, u0, v0,
				xRight + slantTop, yTop, u1, v0,
				xRight + slantBottom, yBottom, u1, v1
			);
			drew = true;
			offset += advance;
		}

		if (drew)
			ctx.draw();
	}
}
