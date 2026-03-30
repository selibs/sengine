package s.graphics.shaders;

class RectangleShader extends Shader2D {
	public function render(context:Context2D, x:Float, y:Float, width:Float, height:Float) {
		super.set(context);
		final ctx = context.context;
		ctx.setVec4(rectCL, x, y, width, height);
		ctx.commit();
	}
}
