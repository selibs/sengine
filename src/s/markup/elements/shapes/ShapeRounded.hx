package s.markup.elements.shapes;

abstract class ShapeRounded extends Shape {
	@:signal public var radius(default, set):Float;
	@:signal public var softness(default, set):Float;

	public function new(radius:Float = 10.0, ?softness:Float = 0.5) {
		super();
		this.radius = radius;
		this.softness = softness;
	}

	inline function set_radius(value:Float)
		return radius = Math.max(0.0, value);

	inline function set_softness(value:Float)
		return softness = Math.max(0.0, value);
}
