package s2d.elements;

import se.Texture;
import se.graphics.Context2D;

class Canvas2D extends DrawableElement {
	@:isVar var texture(default, set):Texture;

	@:signal public function paint(ctx:Context2D):Void;

	public function new() {
		super();
		texture = new Texture(Std.int(width), Std.int(height));
	}

	@:slot(widthChanged, heightChanged)
	function __syncSizeChanged__(_) {
		texture = new Texture(Std.int(width), Std.int(height));
	}

	function draw(target:Texture) {
		final tgtCtx = target.context2D;
		tgtCtx.end();
		texture.context2D.render(true, Transparent, ctx -> paint(ctx));
		tgtCtx.begin();
		tgtCtx.drawImage(texture, absX, absY);
	}

	function set_texture(value:Texture):Texture {
		texture?.unload();
		texture = value;
		return texture;
	}
}
