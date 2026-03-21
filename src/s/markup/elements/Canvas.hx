package s.markup.elements;

import s.Texture;
import s.graphics.Context2D;

class Canvas2D extends DrawableElement {
	var texture:Texture;

	public function new() {
		super();
		texture = new Texture(Std.int(width), Std.int(height));
	}

	public inline function paint(f:Context2D->Void):Void
		texture.context2D.render(true, color, f);

	override function sync() {
		super.sync();
		if (widthIsDirty || heightIsDirty) {
			texture.unload();
			texture = new Texture(Std.int(width), Std.int(height));
		}
	}

	function draw(target:Texture)
		target.context2D.drawImage(texture, left.position, top.position);
}
