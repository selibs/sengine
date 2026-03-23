package s.markup.graphics;

import s.Texture;
import s.markup.elements.Label;

using StringTools;

class TextDrawer extends TexturedElementDrawer<Label> {
	function new() {
		super("text");
	}

	static function findIndex(charCode:Int):Int {
		var blocks = kha.Kravur.KravurImage.charBlocks;
		var offset = 0;
		for (i in 0...Std.int(blocks.length / 2)) {
			var start = blocks[i * 2];
			var end = blocks[i * 2 + 1];
			if (charCode >= start && charCode <= end)
				return offset + charCode - start;
			offset += end - start + 1;
		}
		return 0;
	}

	override function draw(target:Texture, element:Label) @:privateAccess {
		final ctx = target.context3D;
		final atlas = element.fontAsset.asset._get(element.fontSize);
		final tex = atlas.getTexture();
		final quad = new kha.Kravur.AlignedQuad();

		if (element.width == 0.0 || element.height == 0.0)
			return;

		ctx.setTexture(sourceTU, tex);

		var oX = element.displayX;
		var oY = element.displayY;

		for (i in 0...element.displayText.length) {
			final c = element.displayText.fastCodeAt(i);
			final q = atlas.getBakedQuad(quad, findIndex(c), oX, oY);
			if (q == null)
				continue;

			// Match Kha's text quad layout:
			// v0 bottom-left, v1 top-left, v2 top-right, v3 bottom-right.
			ctx.setFloat4(sourceRectCL, (q.x0 - element.left.position) / element.width, (q.y1 - element.top.position) / element.height,
				(q.x1 - q.x0) / element.width, (q.y0 - q.y1) / element.height);

			ctx.setFloat4(sourceClipRectCL, q.s0 * tex.width / tex.realWidth, q.t1 * tex.height / tex.realHeight, (q.s1 - q.s0) * tex.width / tex.realWidth,
				(q.t0 - q.t1) * tex.height / tex.realHeight);

			ctx.draw();

			oX += q.xadvance;
		}
	}
}
