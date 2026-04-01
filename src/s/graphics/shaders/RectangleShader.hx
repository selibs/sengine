package s.graphics.shaders;

class RectangleShader extends Shader2D {
	public function render(context:Context2D, x:Float, y:Float, width:Float, height:Float) {
		super.set(context);
		final ctx = context.context;
		setRect(ctx, x, y, width, height, 0.0, 0.0, 1.0, 1.0);
		ctx.draw();
	}
}
