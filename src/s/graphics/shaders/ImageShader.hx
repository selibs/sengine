package s.graphics.shaders;

import kha.graphics4.ConstantLocation;
import s.assets.Image;

class ImageShader extends TexturedShader {
	public function render(context:Context2D, img:Image, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float) {
		super.set(context);
		final ctx = context.context;

		ctx.setTexture(sourceTU, img);
		ctx.streamQuad(
			dx, dy + dh, sx, sy + sh,
			dx, dy, sx, sy,
			dx + dw, dy, sx + sw, sy,
			dx + dw, dy + dh, sx + sw, sy + sh
		);
		ctx.draw();
	}
}
