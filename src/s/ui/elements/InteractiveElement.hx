package s.ui.elements;

import s.app.input.Mouse;
import s.ui.FocusPolicy;

@:allow(s.ui.Scene)
class InteractiveElement extends Element {
	@:attr(interaction) public var enabled:Bool = true;
	@:attr(interaction) public var focused(default, set):Bool = false;
	@:attr(interaction) public var hovered(default, null):Bool = false;

	public var focusPolicy:FocusPolicy = ClickFocus | TabFocus;

	@:signal public function mouseEntered(x:Float, y:Float);

	@:signal public function mouseExited(x:Float, y:Float);

	@:signal public function mouseMoved(m:MouseMoveEvent);

	@:signal public function mouseScrolled(m:MouseScrollEvent);

	@:signal public function mouseDown(m:MouseButtonEvent);

	@:signal public function mouseUp(m:MouseButtonEvent);

	@:signal public function mouseHold(m:MouseButtonEvent);

	@:signal public function mouseClicked(m:MouseButtonEvent);

	@:signal public function mouseDoubleClicked(m:MouseButtonEvent);

	@:signal(button) public function mouseButtonDown(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonUp(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonHold(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonClicked(button:MouseButton, m:MouseEvent);

	@:signal(button) public function mouseButtonDoubleClicked(button:MouseButton, m:MouseEvent);

	@:slot(mouseDown)
	function syncMouseDown(m:MouseButtonEvent)
		mouseButtonDown(m.button, m);

	@:slot(mouseUp)
	function syncMouseUp(m:MouseButtonEvent)
		mouseButtonUp(m.button, m);

	@:slot(mouseHold)
	function syncMouseHold(m:MouseButtonEvent)
		mouseButtonHold(m.button, m);

	@:slot(mouseClicked)
	function syncMouseClicked(m:MouseButtonEvent)
		mouseButtonClicked(m.button, m);

	@:slot(mouseDoubleClicked)
	function syncMouseDoubleClicked(m:MouseButtonEvent)
		mouseButtonDoubleClicked(m.button, m);

	override function sync() {
		super.sync();
		// if (scene.root.children.dirty)
		// 	scene.interactive.push(this);
	}

	function set_focused(value:Bool) {
		if (value && scene != null)
			scene.focus = this;
		return focused = value;
	}
}
