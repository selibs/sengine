package s2d.graphics;

import kha.graphics4.ConstantLocation;
import se.Texture;
import s2d.elements.shapes.RectangleRounded;

@:access(s2d.Element)
@:dox(hide)
class RectDrawer extends Drawer2D<RectangleRounded> {
	var rectCL:ConstantLocation;
	var rectDataCL:ConstantLocation;
	var bordColCL:ConstantLocation;

	function new() {
		super({
			inputLayout: [["vertCoord" => kha.graphics4.VertexData.Float32_2X]],
			vertexShader: "drawer_colored",
			fragmentShader: "rectangle_rounded",
			alphaBlendSource: SourceAlpha,
			alphaBlendDestination: InverseSourceAlpha,
			blendSource: SourceAlpha,
			blendDestination: InverseSourceAlpha
		});
	}

	override function setup() {
		super.setup();

		rectCL = pipeline.getConstantLocation("rect");
		rectDataCL = pipeline.getConstantLocation("rectData");
		bordColCL = pipeline.getConstantLocation("bordCol");
	}

	function draw(target:Texture, rectangle:RectangleRounded) {
		final ctx = target.context3D;
		final radius = Math.min(rectangle.radius, Math.min(rectangle.width, rectangle.height) * 0.5);
		ctx.setFloat4(rectCL, rectangle.absX, rectangle.absY, rectangle.width, rectangle.height);
		ctx.setFloat3(rectDataCL, radius, rectangle.softness, rectangle.border.width);
		ctx.setFloat4(bordColCL, rectangle.border.color);
		ctx.draw();
	}
}
