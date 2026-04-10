package s.graphics;

import haxe.ds.IntMap;
import s.assets.Font;

typedef FontChar = {
	xoff:Float,
	yoff:Float,
	advance:Float,
	pos:{x:Float, y:Float, width:Float, height:Float},
	uv:{x:Float, y:Float, width:Float, height:Float}
}

private typedef FontCharTemplate = {
	xoff:Float,
	yoff:Float,
	advance:Float,
	width:Float,
	height:Float,
	uvX:Float,
	uvY:Float,
	uvWidth:Float,
	uvHeight:Float
}

enum abstract FontWeight(Int) from Int to Int {
	var Thin = 100;
	var ExtraLight = 200;
	var Light = 300;
	var Normal = 400;
	var Medium = 500;
	var DemiBold = 600;
	var Bold = 700;
	var ExtraBold = 800;
	var Black = 900;
}

enum FontCapitalization {
	MixedCase;
	AllUppercase;
	AllLowercase;
	SmallCaps;
	Capitalize;
}

@:allow(s.graphics.shaders.TextShader)
class FontStyle implements s.shortcut.Shortcut {
	var font:Font = "font_default";
	var cachedAtlas:s.assets.internal.font.FontAtlas = null;
	var cachedPixelSize:Int = -1;
	var cachedLetterSpacing:Float = Math.NaN;
	var cachedWordSpacing:Float = Math.NaN;
	var charTemplates:IntMap<FontCharTemplate> = new IntMap();

	var italicSlant:Float = 0.0;
	var sdfWeight:Float = 0.0;

	public var family:String = "font_default";

	@:inject(setSdfWeight) public var bold:Bool = false;
	public var italic(default, set):Bool = false;
	public var strikeout:Bool = false; // TODO
	public var underline:Bool = false; // TODO
	public var snapToPixel:Bool = true;

	@:attr(spacing) public var wordSpacing:Float = 0.0;
	@:attr(spacing) public var letterSpacing:Float = 0.0;

	@:inject(setSdfWeight) public var weight:FontWeight = Normal;
	public var softness:Float = 0.0;
	public var outlineColor:Color = Transparent;
	public var outlineWidth:Float = 0.0;

	// public var backgroundColor:Color = Transparent; // TODO
	// public var capitalization:FontCapitalization; // TODO
	public var pointSize(get, set):Float;
	@:attr(metrics) public var pixelSize(default, set):Int = 18;

	// public var preferShaping:Bool;
	// public var preferTypoLineMetrics:Bool;
	// public var styleName:String;
	// public var variableAxes:object;
	// public var contextFontMerging:Bool;
	// public var features:object;
	// public var hintingPreference:enumeration;
	// public var kerning:Bool;
	@:readonly @:alias public var isLoaded:Bool = font.isLoaded;

	public function new() {}

	public inline function getAtlas()
		return font.getAtlas(pixelSize);

	inline function invalidateCharTemplates() {
		cachedAtlas = null;
		cachedPixelSize = -1;
		cachedLetterSpacing = Math.NaN;
		cachedWordSpacing = Math.NaN;
		charTemplates = new IntMap();
	}

	inline function getTemplateAtlas() {
		final atlas = getAtlas();
		if (atlas != cachedAtlas || cachedPixelSize != pixelSize || cachedLetterSpacing != letterSpacing || cachedWordSpacing != wordSpacing) {
			cachedAtlas = atlas;
			cachedPixelSize = pixelSize;
			cachedLetterSpacing = letterSpacing;
			cachedWordSpacing = wordSpacing;
			charTemplates = new IntMap();
		}
		return atlas;
	}

	inline function buildFontCharTemplate(atlas:s.assets.internal.font.FontAtlas, scale:Float, char:Int):FontCharTemplate {
		final g = atlas.getGlyph(char);
		final atlasW:Float = g.x1 - g.x0;
		final atlasH:Float = g.y1 - g.y0;
		return {
			xoff: g.xoff * scale,
			yoff: g.yoff * scale,
			advance: g.xadvance + getSpacing(char),
			width: atlasW / s.assets.internal.font.Font.sdfOversample * scale,
			height: atlasH / s.assets.internal.font.Font.sdfOversample * scale,
			uvX: g.x0 / atlas.width,
			uvY: g.y0 / atlas.height,
			uvWidth: atlasW / atlas.width,
			uvHeight: atlasH / atlas.height
		};
	}

	inline function copyFontCharTemplate(template:FontCharTemplate, out:FontChar):FontChar {
		if (out == null)
			return {
				xoff: template.xoff,
				yoff: template.yoff,
				advance: template.advance,
				pos: {
					x: 0.0,
					y: 0.0,
					width: template.width,
					height: template.height
				},
				uv: {
					x: template.uvX,
					y: template.uvY,
					width: template.uvWidth,
					height: template.uvHeight
				}
			};

		out.xoff = template.xoff;
		out.yoff = template.yoff;
		out.advance = template.advance;
		out.pos.width = template.width;
		out.pos.height = template.height;
		out.uv.x = template.uvX;
		out.uv.y = template.uvY;
		out.uv.width = template.uvWidth;
		out.uv.height = template.uvHeight;
		return out;
	}

	public inline function getFontCharFromAtlas(atlas:s.assets.internal.font.FontAtlas, scale:Float, char:Int):FontChar {
		return copyFontCharTemplate(buildFontCharTemplate(atlas, scale, char), null);
	}

	public function copyFontChar(char:Int, out:FontChar = null):FontChar {
		final atlas = getTemplateAtlas();
		final template = charTemplates.get(char);
		if (template != null)
			return copyFontCharTemplate(template, out);

		final scale = pixelSize / atlas.size;
		final built = buildFontCharTemplate(atlas, scale, char);
		charTemplates.set(char, built);
		return copyFontCharTemplate(built, out);
	}

	public function getFontChar(char:Int):FontChar {
		return copyFontChar(char);
	}

	public function widthOfCharacters(chars:Array<Int>, start:Int, length:Int):Float {
		if (pixelSize <= 0 || chars == null || length <= 0)
			return 0.0;

		var atlas = getAtlas();
		var scale = pixelSize / atlas.size;
		var end = Std.int(Math.min(start + length, chars.length));

		var width = 0.0;
		for (i in start...end) {
			var char = chars[i];
			width += atlas.getGlyph(char).xadvance * scale;
			if (i < end - 1)
				width + getSpacing(char);
		}

		return width;
	}

	public function widthOfString(text:String, start:Int, length:Int):Float {
		if (pixelSize <= 0 || text == null || length <= 0)
			return 0.0;

		final atlas = getAtlas();
		final scale = pixelSize / atlas.size;
		final end = Std.int(Math.min(start + length, text.length));

		var width = 0.0;
		for (i in start...end)
			width += atlas.getGlyph(text.charCodeAt(i)).xadvance * scale;

		return width;
	}

	inline function getSpacing(char:Int) {
		var spacing = letterSpacing;
		if (char == " ".code || char == "\t".code)
			spacing += wordSpacing;
		return spacing;
	}

	inline function get_pointSize():Float
		return pixelSize * 72.0 / s.app.Display.primary.pixelsPerInch;

	inline function set_pointSize(value:Float):Float {
		pixelSize = Std.int(value * s.app.Display.primary.pixelsPerInch / 72.0);
		return value;
	}

	inline function setSdfWeight()
		sdfWeight = ((weight : Int) - (FontWeight.Medium : Int)) / 400.0 * 0.5 + (bold ? 0.75 : 0.0);

	inline function set_italic(value:Bool) {
		italicSlant = value ? 0.21256 : 0.0;
		return italic = value;
	}

	inline function set_outlineWidth(value:Float)
		return outlineWidth = Math.max(0.0, value);

	inline function set_softness(value:Float)
		return softness = Math.max(0.0, value);

	inline function set_pixelSize(value:Int):Int
		return pixelSize = value > 0 ? value : 0;
}
