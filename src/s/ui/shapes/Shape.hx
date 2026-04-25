package s.ui.shapes;

@:allow(s.ui.graphics.shapes.ShapeDrawer)
abstract class Shape extends s.ui.elements.Drawable {
	var realRadius:Float = 0.0;

	@:attr.attached public final border:BorderAttribute;
	@:attr @:clamp(0) public var radius:Float;
	@:attr @:clamp(0) public var softness:Float = 0.5;

	public function new(radius:Float = 5.0) {
		super();
		this.radius = radius;
		border = new BorderAttribute(this);
	}

	override function update() {
		super.update();

		if (radiusDirty || widthDirty || heightDirty)
			realRadius = Math.min(radius, Math.min(width, height) * 0.5);
	}
}
