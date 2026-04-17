package s.ui.elements;

import s.graphics.RenderTarget;
import s.graphics.Context2D;

class Canvas extends Drawable {
	var texture:RenderTarget;

	public function new() {
		super();
		texture = new RenderTarget(Std.int(width), Std.int(height));
	}

	public inline function paint(f:Context2D->Void):Void
		texture.context2D.render(true, color, f);

	@:slot(update)
	function updateTexture(_)
		if (widthDirty || heightDirty) {
			texture.unload();
			texture = new RenderTarget(Std.int(width), Std.int(height));
		}

	function draw(target:RenderTarget) {
		final ctx = target.context2D;
		ctx.pushTransform(globalTransform);
		ctx.drawImage(texture, left.position, top.position);
		ctx.popTransform();
	}
}
