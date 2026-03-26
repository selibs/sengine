package s.markup;

import s.assets.Font;

typedef ElementFontChar = {
	xoff:Float,
	yoff:Float,
	advance:Float,
	pos:s.geometry.Rect,
	uv:s.geometry.Rect
}

@:allow(s.markup.Element)
class ElementFont implements s.shortcut.Shortcut {
	var font:Font = new Font();

	@:attr public var bold:Bool = false;
	// @:attr public var capitalization:enumeration;
	// @:attr public var contextFontMerging:Bool;
	@:attr public var family:String = "font_default";
	// @:attr public var features:object;
	// @:attr public var hintingPreference:enumeration;
	// @:attr public var italic:Bool;
	// @:attr public var kerning:Bool;
	// @:attr public var letterSpacing:Float;
	@:attr public var pixelSize(default, set):Int = 18;

	// @:attr public var pointSize:Float;
	// @:attr public var preferShaping:Bool;
	// @:attr public var preferTypoLineMetrics:Bool;
	// @:attr public var strikeout:Bool;
	// @:attr public var styleName:String;
	// @:attr public var underline:Bool;
	// @:attr public var variableAxes:object;
	// @:attr public var weight:Int;
	// @:attr public var wordSpacing:Float;

	public function new() {
		font.onLoaded(() -> isDirty = true);
	}

	public function getAtlas()
		return font.getAtlas(pixelSize);

	public function getElementChar(index:Int):ElementFontChar {
		var atlas = getAtlas();
		var g = atlas.getGlyph(index);
		var atlasW:Float = g.x1 - g.x0;
		var atlasH:Float = g.y1 - g.y0;
		var w:Float = atlasW / s.assets.font.Font.sdfOversample;
		var h:Float = atlasH / s.assets.font.Font.sdfOversample;
		return {
			xoff: g.xoff,
			yoff: g.yoff,
			advance: g.xadvance,
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

	function set_pixelSize(value:Int):Int
		return pixelSize = value > 0 ? value : 0;
}
