package s2d.elements;

import se.math.Mat3;
import se.math.SMath;
import se.system.input.Mouse;

class InteractiveElement extends Element {
	@:attr public var enabled:Bool = true;
	@:attr public var hovered:Bool = false;

	@:signal public function mouseEntered(x:Float, y:Float);

	@:signal public function mouseExited(x:Float, y:Float);

	@:signal public function mouseMoved(m:MouseMoveEvent);

	@:signal public function mouseScrolled(m:MouseScrollEvent);

	@:signal public function mousePressed(m:MouseButtonEvent);

	@:signal public function mouseReleased(m:MouseButtonEvent);

	@:signal public function mouseHold(m:MouseButtonEvent);

	@:signal public function mouseClicked(m:MouseButtonEvent);

	@:signal public function mouseDoubleClicked(m:MouseButtonEvent);

	@:signal(button) public function mouseButtonPressed(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonReleased(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonHold(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonClicked(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonDoubleClicked(button:MouseButton, m:MouseEvent);

	override function render(target:se.Texture) {
		update(target.context2D.transform);
		super.render(target);
	}

	function update(t:Mat3) {
		var m = se.App.input.mouse;
		var mx = m.x;
		var my = m.y;

		var p = inverse(t) * vec2(mx, my);
		var containsMouse = left.position <= p.x && p.x <= right.position && top.position <= p.y && p.y <= bottom.position;

		if (!hovered && containsMouse)
			mouseEntered(mx, my);
		else if (hovered && !containsMouse)
			mouseExited(mx, my);
	}

	@:slot(mouseEntered)
	function syncMouseEntered(x:Float, y:Float) {
		hovered = true;
	}

	@:slot(mouseExited)
	function syncMouseExited(x:Float, y:Float) {
		hovered = false;
	}

	@:slot(mousePressed)
	function syncMousePressed(m:MouseButtonEvent)
		mouseButtonPressed(m.button, m);

	@:slot(mouseReleased)
	function syncMouseReleased(m:MouseButtonEvent)
		mouseButtonReleased(m.button, m);

	@:slot(mouseHold)
	function syncMouseHold(m:MouseButtonEvent)
		mouseButtonHold(m.button, m);

	@:slot(mouseClicked)
	function syncMouseClicked(m:MouseButtonEvent)
		mouseButtonClicked(m.button, m);

	@:slot(mouseDoubleClicked)
	function syncMouseDoubleClicked(m:MouseButtonEvent)
		mouseButtonDoubleClicked(m.button, m);
}
