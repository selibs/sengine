package s.ui.elements;

import s.ui.FocusPolicy;
import s.app.input.Mouse;
import s.app.input.Keyboard;

typedef MouseEvent = {accepted:Bool, x:Int, y:Int}
typedef MouseMoveEvent = {> MouseEvent, dx:Int, dy:Int}
typedef MouseScrollEvent = {> MouseEvent, delta:Int}
typedef MouseButtonEvent = {> MouseEvent, button:MouseButton}

@:allow(s.app.Window)
class Interactive extends Element {
	final holdTimers:Map<MouseButton, Timer> = [];
	final doubleClickTimers:Map<MouseButton, Timer> = [];

	public var cursor:MouseCursor = Pointer;
	public var acceptedButtons:MouseButton = MouseButton.Left;
	public var focusPolicy:FocusPolicy = ClickFocus | TabFocus;
	public var holdInterval:Float = 0.3;
	public var doubleClickInterval:Float = 0.5;

	@:attr(interaction) public var isEnabled:Bool = true;
	@:attr(interaction) public var isFocused(default, set):Bool = false;

	public var pressedButtons(default, null):MouseButton = 0;

	public var isHovered(default, null):Bool = false;
	public var mouseX(default, null):Float = 0.0;
	public var mouseY(default, null):Float = 0.0;

	public var isPressed(default, null):Bool = false;
	public var pressX(default, null):Float = 0.0;
	public var pressY(default, null):Float = 0.0;

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

	@:slot(mouseMoved)
	function updateMouseMoved(m:MouseMoveEvent) {
		mouseX = m.x;
		mouseY = m.y;
	}

	@:slot(mouseEntered)
	function updateMouseEntered(x:Float, y:Float) {
		mouseX = x;
		mouseY = y;
		isHovered = true;
		scene.window.mouse.cursor = cursor;
	}

	@:slot(mouseExited)
	function updateMouseExited(x:Float, y:Float) {
		mouseX = x;
		mouseY = y;
		isHovered = false;
		scene.window.mouse.cursor = Default;

		for (b in holdTimers.keys())
			holdTimers[b].stop();
		holdTimers.clear();
	}

	@:slot(mouseDown)
	function updateMouseDown(m:MouseButtonEvent) {
		pressX = m.x;
		pressY = m.y;
		isPressed = true;
		pressedButtons |= m.button;

		holdTimers[m.button] = Timer.set(() -> {
			holdTimers.remove(m.button);
			mouseHold(m);
		}, holdInterval);

		mouseButtonDown(m.button, m);
	}

	@:slot(mouseUp)
	function updateMouseUp(m:MouseButtonEvent) {
		isPressed = false;
		final timer = holdTimers[m.button];
		if (timer != null) {
			timer.stop();
			holdTimers.remove(m.button);
			mouseClicked(m);
		}

		mouseButtonUp(m.button, m);
	}

	@:slot(mouseHold)
	function updateMouseHold(m:MouseButtonEvent)
		mouseButtonHold(m.button, m);

	@:slot(mouseClicked)
	function updateMouseClicked(m:MouseButtonEvent)
		mouseButtonClicked(m.button, m);

	@:slot(mouseDoubleClicked)
	function updateMouseDoubleClicked(m:MouseButtonEvent)
		mouseButtonDoubleClicked(m.button, m);

	@:slot(keyboardDown)
	function updateKeyboardDown(key:KeyCode)
		keyboardKeyDown(key);

	@:slot(keyboardUp)
	function updateKeyboardUp(key:KeyCode)
		keyboardKeyUp(key);

	@:slot(keyboardHold)
	function updateKeyboardHold(key:KeyCode)
		keyboardKeyHold(key);

	@:slot(keyboardPressed)
	function updateKeyboardPressed(char:String)
		keyboardCharPressed(char);

	@:slot(update)
	function updateOrder(_)
		if (globalVisible && scene.children.dirty)
			scene.interactive.push(this);

	function set_focused(value:Bool) {
		if (value && scene != null) {
			scene.focus = this;
			return isFocused = true;
		}
		return isFocused = false;
	}
}
