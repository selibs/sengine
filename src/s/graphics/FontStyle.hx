package s.graphics;

import s.assets.Font;

typedef FontChar = {
	xoff:Float,
	yoff:Float,
	advance:Float,
	pos:{x:Float, y:Float, width:Float, height:Float},
	uv:{x:Float, y:Float, width:Float, height:Float}
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

	var italicSlant:Float = 0.0;
	var sdfWeight:Float = 0.0;

	public var family:String = "font_default";

	@:inject(setSdfWeight) public var bold:Bool = false;
	public var italic(default, set):Bool = false;
	public var strikeout:Bool = false; // TODO
	public var underline:Bool = false; // TODO
	public var snapToPixel:Bool = true;

	@:attr public var wordSpacing:Float = 0.0;
	@:attr public var letterSpacing:Float = 0.0;

	@:inject(setSdfWeight) public var weight:FontWeight = Normal;
	public var softness:Float = 0.0;
	public var outlineColor:Color = Transparent;
	public var outlineWidth:Float = 0.0;

	// public var backgroundColor:Color = Transparent; // TODO
	// public var capitalization:FontCapitalization; // TODO
	public var pointSize(get, set):Float;
	@:attr public var pixelSize(default, set):Int = 18;

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

	public inline function getFontCharFromAtlas(atlas:s.assets.font.FontAtlas, scale:Float, char:Int):FontChar {
		var g = atlas.getGlyph(char);
		var atlasW:Float = g.x1 - g.x0;
		var atlasH:Float = g.y1 - g.y0;
		var w:Float = atlasW / s.assets.font.Font.sdfOversample * scale;
		var h:Float = atlasH / s.assets.font.Font.sdfOversample * scale;
		return {
			xoff: g.xoff * scale,
			yoff: g.yoff * scale,
			advance: g.xadvance + getSpacing(char),
			pos: {
				x: 0.0,
				y: 0.0,
				width: w,
				height: h
			},
			uv: {
				x: g.x0 / atlas.width,
				y: g.y0 / atlas.height,
				width: atlasW / atlas.width,
				height: atlasH / atlas.height
			}
		}
	}

	public function getFontChar(char:Int):FontChar {
		var atlas = getAtlas();
		var scale = pixelSize / atlas.size;
		return getFontCharFromAtlas(atlas, scale, char);
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
		return pixelSize * 72.0 / s.Display.primary.pixelsPerInch;

	inline function set_pointSize(value:Float):Float {
		pixelSize = Std.int(value * s.Display.primary.pixelsPerInch / 72.0);
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
