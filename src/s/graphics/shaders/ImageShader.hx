package s.graphics.shaders;

import s.assets.Image;

class ImageShader extends TexturedShader {
	public function render(context:Context2D, img:Image, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float) {
		super.set(context);
		final ctx = context.context;

		ctx.setTexture(sourceTU, img);
		setRect(ctx, dx, dy, dw, dh, sx, sy, sw, sh);
		ctx.flush();
	}
}
