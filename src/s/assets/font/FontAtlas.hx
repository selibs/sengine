package s.assets.font;

import haxe.ds.IntMap;
import kha.Kravur;
import kha.graphics2.truetype.StbTruetype;

class FontAtlas extends KravurImage {
	public static inline function get(font:Font, size:Int)
		return font.getAtlas(size);

	public var size(default, null):Int = 0;

	public inline function getGlyph(char:Int):Stbtt_bakedchar
		return chars[getCharIndex(char)];

	public function getCharIndex(char:Int):Int {
		static var charIndices:IntMap<Int> = new IntMap();

		var ind = charIndices.get(char);
		if (ind == null) {
			var blocks = kha.Kravur.KravurImage.charBlocks;
			var offset = 0;

			for (i in 0...Std.int(blocks.length / 2)) {
				var start = blocks[i * 2];
				var end = blocks[i * 2 + 1];
				if (char >= start && char <= end) {
					ind = offset + char - start;
					break;
				}
				offset += end - start + 1;
			}

			ind = ind ?? 0;
			charIndices.set(char, ind);
		}

		return ind;
	}
}
