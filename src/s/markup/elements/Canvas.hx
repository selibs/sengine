package s.markup.elements;

import s.Texture;
import s.graphics.Context2D;

class Canvas2D extends DrawableElement {
	var texture:Texture;

	public function new() {
		super();
		texture = new Texture(Std.int(width.real), Std.int(height.real));
	}

	public inline function paint(f:Context2D->Void):Void
		texture.context2D.render(true, color, f);

	override function sync(target:Texture) {
		super.sync(target);
		if (width.realIsDirty || height.realIsDirty) {
			texture.unload();
			texture = new Texture(Std.int(width.real), Std.int(height.real));
		}
	}

	function draw(target:Texture)
		target.context2D.drawImage(texture, left.position, top.position);
}
