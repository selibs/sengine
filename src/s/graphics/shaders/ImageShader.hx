package s.graphics.shaders;

import kha.graphics4.ConstantLocation;
import s.assets.Image;

class ImageShader extends TexturedShader {
	public function render(context:Context2D, img:Image, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float) {
		super.set(context);

		final ctx = context.context;
		ctx.setTexture(sourceTU, img);
		ctx.setVec4(rectCL, dx, dy, dw, dh);
		ctx.setVec4(clipRectCL, sx, sy, sw, sh);
		ctx.draw();
	}
}
