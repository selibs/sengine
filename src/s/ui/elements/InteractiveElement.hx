package s.ui.elements;

import s.ui.FocusPolicy;
import s.app.input.Mouse;
import s.app.input.Keyboard;

@:allow(s.app.Window)
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

	@:signal public function keyboardDown(key:KeyCode);

	@:signal public function keyboardUp(key:KeyCode);

	@:signal public function keyboardHold(key:KeyCode);

	@:signal public function keyboardPressed(char:String);

	@:signal public function keyboardHotkey(hotkey:Array<KeyCode>);

	@:signal(key) public function keyboardKeyDown(key:KeyCode);

	@:signal(key) public function keyboardKeyUp(key:KeyCode);

	@:signal(key) public function keyboardKeyHold(key:KeyCode);

	@:signal(char) public function keyboardCharPressed(char:String);

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

	@:slot(keyboardDown)
	function syncKeyboardDown(key:KeyCode)
		keyboardKeyDown(key);

	@:slot(keyboardUp)
	function syncKeyboardUp(key:KeyCode)
		keyboardKeyUp(key);

	@:slot(keyboardHold)
	function syncKeyboardHold(key:KeyCode)
		keyboardKeyHold(key);

	@:slot(keyboardPressed)
	function syncKeyboardPressed(char:String)
		keyboardCharPressed(char);

	@:slot(sync)
	function syncOrder(_)
		if (globalVisible && scene.root.children.dirty)
			scene.interactive.push(this);

	function set_focused(value:Bool) {
		if (value && scene != null)
			scene.focus = this;
		return focused = value;
	}
}
