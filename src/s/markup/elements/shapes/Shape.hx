package s.markup.elements.shapes;

@:allow(s.markup.graphics.shapes.ShapeDrawer)
abstract class Shape extends DrawableElement {
	var realRadius:Float = 0.0;

	@:attr public var radius:Float;
	public var border = {width: 0.0, color: Color.Transparent};

	public function new(radius:Float = 5.0) {
		super();
		this.radius = radius;
	}

	override function sync(target:Texture) {
		super.sync(target);

		if (radiusIsDirty || widthIsDirty || heightIsDirty) {
			realRadius = Math.max(0.0, radius);
			realRadius = Math.min(realRadius, Math.min(width, height) * 0.5);
		}
	}
}
