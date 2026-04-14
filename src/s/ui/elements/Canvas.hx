package s.ui.elements;

import s.graphics.RenderTarget;
import s.graphics.Context2D;

class Canvas extends DrawableElement {
	var texture:RenderTarget;

	public function new() {
		super();
		texture = new RenderTarget(Std.int(width), Std.int(height));
	}

	public inline function paint(f:Context2D->Void):Void
		texture.context2D.render(true, color, f);

	@:slot(sync)
	function syncTexture(_)
		if (widthDirty || heightDirty) {
			texture.unload();
			texture = new RenderTarget(Std.int(width), Std.int(height));
		}

	function draw(target:RenderTarget)
		target.context2D.drawImage(texture, left.position, top.position);
}
