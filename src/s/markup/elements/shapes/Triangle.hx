package s.markup.elements.shapes;

import s.Texture;
import s.math.Vec2;

@:allow(s.markup.graphics.shapes.TriangleDrawer)
class Triangle extends Shape {
	var realPoint1:Vec2 = new Vec2(0.0, 0.0);
	var realPoint2:Vec2 = new Vec2(0.0, 0.0);
	var realPoint3:Vec2 = new Vec2(0.0, 0.0);

	@:attr @:attr.group public var point1:ElementPoint;
	@:attr @:attr.group public var point2:ElementPoint;
	@:attr @:attr.group public var point3:ElementPoint;

	public function new(radius:Float = 10.0) {
		super(radius);
		point1 = {x: "0%", y: "100%"};
		point2 = {x: "50%", y: "0%"};
		point3 = {x: "100%", y: "100%"};
	}

	override function sync(target:Texture) {
		super.sync(target);
		DrawableElement.syncPoint(this, target, realPoint1, point1, point1IsDirty);
		DrawableElement.syncPoint(this, target, realPoint2, point2, point2IsDirty);
		DrawableElement.syncPoint(this, target, realPoint3, point3, point3IsDirty);
	}

	function draw(target:s.Texture) {
		s.markup.graphics.shapes.TriangleDrawer.shader.render(target, this);
	}
}
