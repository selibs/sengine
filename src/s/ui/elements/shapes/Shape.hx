package s.ui.elements.shapes;

@:allow(s.ui.graphics.shapes.ShapeDrawer)
abstract class Shape extends Drawable {
	var realRadius:Float = 0.0;

	@:attr.attached public final border:BorderAttribute;
	@:attr @:clamp(0) public var radius:Float;

	public function new(radius:Float = 5.0) {
		super();
		this.radius = radius;
		border = new BorderAttribute(this);
	}

	@:slot(update)
	function updateRealRadius(_)
		if (radiusDirty || widthDirty || heightDirty)
			realRadius = Math.min(radius, Math.min(width, height) * 0.5);
}
