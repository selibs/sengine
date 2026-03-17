package s.markup.elements;

import s.system.Texture;
import s.system.graphics.Context2D;

class Canvas2D extends DrawableElement {
	var texture(default, set):Texture;

	dynamic function paint(ctx:Context2D):Void {}

	public function new() {
		super();
		texture = new Texture(Std.int(width), Std.int(height));
	}

	@:slot(widthDirty, heightDirty)
	function __syncSizeChanged__(_) {
		texture = new Texture(Std.int(width), Std.int(height));
	}

	function draw(target:Texture) {
		final tgtCtx = target.context2D;
		tgtCtx.end();
		texture.context2D.render(true, color, ctx -> paint(ctx));
		tgtCtx.begin();
		tgtCtx.drawImage(texture, left.position, top.position);
	}

	function set_texture(value:Texture):Texture {
		texture?.unload();
		texture = value;
		return texture;
	}
}
