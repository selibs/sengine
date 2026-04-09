package s.ui.elements.shapes;

@:allow(s.ui.graphics.shapes.ShapeDrawer)
abstract class Shape extends DrawableElement {
	var realRadius:Float = 0.0;

	@:attr.attached public final border:BorderAttribute;
	@:attr @:clamp(0) public var radius:Float;

	public function new(radius:Float = 5.0) {
		super();
		this.radius = radius;
		border = new BorderAttribute(this);
	}

	override function sync() {
		super.sync();

		if (radiusDirty || horizontalDirty || verticalDirty)
			realRadius = Math.min(realRadius, Math.min(width, height) * 0.5);
	}
}
