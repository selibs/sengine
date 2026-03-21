package s.markup.graphics.shapes;

import kha.graphics4.ConstantLocation;
import s.Texture;
import s.markup.elements.shapes.Ellipse;

@:allow(s.markup.elements.shapes.Ellipse)
class EllipseDrawer extends ShapeDrawer<Ellipse> {
	var centerCL:ConstantLocation;
	var scaleCL:ConstantLocation;

	function new() {
		super("ellipse");
	}

	override function setup() {
		super.setup();
		centerCL = pipeline.getConstantLocation("center");
		scaleCL = pipeline.getConstantLocation("scale");
	}

	override function setUniforms(target:Texture, element:Ellipse) @:privateAccess {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setVec2(centerCL, element.realCenter);
		ctx.setFloat2(scaleCL, element.scaleX, element.scaleY);
	}
}
