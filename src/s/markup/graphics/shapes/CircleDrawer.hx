package s.markup.graphics.shapes;

import kha.graphics4.ConstantLocation;
import s.Texture;
import s.markup.elements.shapes.Circle;

@:allow(s.markup.elements.shapes.Circle)
class CircleDrawer extends ShapeDrawer<Circle> {
	var centerCL:ConstantLocation;

	function new() {
		super("circle");
	}

	override function setup() {
		super.setup();
		centerCL = pipeline.getConstantLocation("center");
	}

	override function setUniforms(target:Texture, element:Circle) {
		super.setUniforms(target, element);
		final ctx = target.context3D;
		ctx.setVec2(centerCL, element.realCenter);
	}
}
