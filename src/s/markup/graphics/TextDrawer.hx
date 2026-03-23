package s.markup.graphics;

import s.graphics.shaders.Shader;
import s.markup.elements.Label;

class TextDrawer extends TexturedElementDrawer<Label> {
	function new() {
		super("text");
	}

	override function setBuffers(target:Texture) {
		final ctx = target.context3D;
		ctx.setIndexBuffer(Shader.indices2D);
		ctx.setVertexBuffer(Shader.vertices2D);
	}

	override function draw(target:Texture, element:Label) {
		final ctx = target.context3D;
		ctx.setTexture(sourceTU, Label.getAtlas(element.fontAsset.asset, element.fontSize).getTexture());

		for (c in element.chars) {
			ctx.setFloat4(rectCL, c.pos.x, c.pos.y, c.pos.width, c.pos.height);
			ctx.setFloat4(clipRectCL, c.uv);
			ctx.draw();
		}
	}
}
