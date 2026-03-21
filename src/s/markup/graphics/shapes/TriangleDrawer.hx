package s.markup.graphics.shapes;

import kha.graphics4.ConstantLocation;
import s.Texture;
import s.markup.elements.shapes.Triangle;

@:allow(s.markup.elements.shapes.Triangle)
class TriangleDrawer extends ShapeDrawer<Triangle> {
	var point1CL:ConstantLocation;
	var point2CL:ConstantLocation;
	var point3CL:ConstantLocation;

	function new() {
		super("triangle");
	}

	override function setup() {
		super.setup();
		point1CL = pipeline.getConstantLocation("point1");
		point2CL = pipeline.getConstantLocation("point2");
		point3CL = pipeline.getConstantLocation("point3");
	}

	override function setUniforms(target:Texture, element:Triangle) {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setVec2(point1CL, element.realPoint1);
		ctx.setVec2(point2CL, element.realPoint2);
		ctx.setVec2(point3CL, element.realPoint3);
	}
}
