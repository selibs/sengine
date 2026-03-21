package s.markup.elements.shapes;

import s.Texture;
import s.math.Vec2;

@:allow(s.markup.graphics.shapes.CircleDrawer)
class Circle extends Shape {
	var realCenter:Vec2 = new Vec2(0.0, 0.0);

	@:attr @:attr.group public var center:ElementPoint;

	public function new(radius:Float = 10.0) {
		super(radius);
		center = {x: "50%", y: "50%"};
	}

	override function sync(target:Texture) {
		super.sync(target);

		center.x.self.resolve(width.real, target.width, target.height);
		center.y.self.resolve(height.real, target.width, target.height);
		if (centerIsDirty || center.xIsDirty || center.x.realIsDirty)
			realCenter.x = left.position + center.x.real;
		if (centerIsDirty || center.yIsDirty || center.y.realIsDirty)
			realCenter.y = top.position + center.y.real;
	}

	function draw(target:s.Texture) {
		s.markup.graphics.shapes.CircleDrawer.shader.render(target, this);
	}
}
