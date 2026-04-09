package s.ui.graphics;

import kha.graphics4.ConstantLocation;
import s.graphics.RenderTarget;
import s.graphics.shaders.Shader;
import s.ui.elements.DrawableElement;

@:allow(s.ui.elements.DrawableElement)
@:access(s.ui.elements.DrawableElement)
abstract class ElementDrawer<T:DrawableElement> extends Shader {
	var mvpCL:ConstantLocation;
	var rectCL:ConstantLocation;
	var colorCL:ConstantLocation;

	function new(frag:String, vert:String = "element") {
		super({
			inputLayout: [Shader.structure2D],
			vertexShader: vert,
			fragmentShader: frag,
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	override function setup() {
		mvpCL = pipeline.getConstantLocation("mvp");
		rectCL = pipeline.getConstantLocation("rect");
		colorCL = pipeline.getConstantLocation("color");
	}

	public function render(target:RenderTarget, element:T) {
		final ctx = target.context3D;
		ctx.setPipeline(pipeline);
		setBuffers(target);
		setUniforms(target, element);
		draw(target, element);
	}

	function setUniforms(target:RenderTarget, element:T) {
		final ctx = target.context3D;
		ctx.setMat3(mvpCL, element.globalTransform * target.context2D.transform);
		ctx.setVec4(rectCL, element.left.position, element.top.position, element.width, element.height);
		ctx.setVec4(colorCL, element.realColor);
	}

	function setBuffers(target:RenderTarget) {
		final ctx = target.context3D;
		ctx.setMesh(Shader.quad);
	}

	function draw(target:RenderTarget, element:T):Void {
		final ctx = target.context3D;
		ctx.flush();
	}
}
