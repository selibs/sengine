package s.assets.internal.font;

import haxe.ds.IntMap;
import haxe.ds.Vector;
import kha.Blob;
import kha.Kravur;
import kha.graphics2.truetype.StbTruetype;

class FontAtlas extends KravurImage {
	public static inline function get(font:Font, size:Int)
		return font.getAtlas(size);

	final charIndices:IntMap<Int> = new IntMap();
	var fallbackIndex:Int = 0;

	public var size(default, null):Int = 0;
	public var sdfRange(default, null):Float = 0.0;

	public function new(size:Int, ascent:Int, descent:Int, lineGap:Int, width:Int, height:Int, chars:Vector<Stbtt_bakedchar>, pixels:Blob, glyphs:Array<Int>,
			sdfRange:Float) {
		super(size, ascent, descent, lineGap, width, height, chars, pixels);
		this.size = size;
		this.sdfRange = sdfRange;

		var questionMarkIndex = -1;
		var spaceIndex = -1;
		for (i in 0...glyphs.length) {
			final glyph = glyphs[i];
			charIndices.set(glyph, i);
			if (glyph == "?".code)
				questionMarkIndex = i;
			else if (glyph == " ".code)
				spaceIndex = i;
		}

		fallbackIndex = questionMarkIndex >= 0 ? questionMarkIndex : spaceIndex >= 0 ? spaceIndex : 0;
	}

	public inline function getGlyph(char:Int):Stbtt_bakedchar
		return chars[getCharIndex(char)];

	public function getCharIndex(char:Int):Int {
		final ind = charIndices.get(char);
		return ind ?? fallbackIndex;
	}
}
