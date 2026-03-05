package s2d.elements.shapes;

import se.Texture;
import s2d.geometry.Rect;
import s2d.graphics.Drawers;

@:allow(s2d.graphics.RectDrawer)
@:access(s2d.graphics.RectDrawer)
class RoundedRectangle extends Shape {
	var _rect:Rect = new Rect(0.0, 0.0, 0.0, 0.0);
	var _radius:Float = 0.0;

	@track @:isVar public var radius(default, set):Float;
	@track @:isVar public var softness(default, set):Float;

	public function new(radius:Float = 10.0, ?softness:Float = 0.5) {
		super();
		this.radius = radius;
		this.softness = softness;
	}

	function draw(target:Texture) {
		Drawers.rectDrawer.render(target, this);
	}

	@:slot(radiusChanged, widthChanged, heightChanged)
	function syncRadius(_:Float = 0.0) {
		_radius = Math.min(radius, Math.min(width, height) * 0.5);
	}

	@:slot(softnessChanged, absXChanged, absYChanged, widthChanged, heightChanged)
	function syncSoftness(_:Float = 0.0) {
		_rect.x = absX - softness;
		_rect.y = absY - softness;
		_rect.width = width + softness * 2;
		_rect.height = height + softness * 2;
	}

	function set_radius(value:Float) {
		radius = Math.max(0.0, value);
		return radius;
	}

	function set_softness(value:Float) {
		softness = Math.max(0.0, value);
		return softness;
	}
}
