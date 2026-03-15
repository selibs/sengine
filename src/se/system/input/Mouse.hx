package se.system.input;

typedef MouseCursor = kha.input.Mouse.MouseCursor;

typedef MouseEvent = {
	var accepted:Bool;
	var x:Int;
	var y:Int;
}

typedef MouseButtonEvent = {
	> MouseEvent,
	var button:MouseButton;
}

typedef MouseScrollEvent = {
	> MouseEvent,
	var delta:Int;
}

typedef MouseMoveEvent = {
	> MouseEvent,
	var dx:Int;
	var dy:Int;
}

enum abstract MouseButton(Int) from Int to Int {
	var Left;
	var Right;
	var Middle;
	var Back;
	var Forward;

	@:to
	public function toString():String
		return 'MouseButton.${[Left => "Left", Right => "Right", Middle => "Middle", Back => "Back", Forward => "Forward"].get(this)}';
}

class Mouse implements s.shortcut.Shortcut {
	var mouse:kha.input.Mouse;

	var buttonsDown:Array<MouseButton> = [];
	var recentlyPressed:Map<MouseButton, Timer> = [];
	var recentlyClicked:Map<MouseButton, Timer> = [];
	var buttonHoldTimers:Map<MouseButton, Timer> = [];

	public var holdInterval = 0.8;
	public var clickInterval = 0.3;
	public var doubleClickInterval = 0.5;

	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var visible(default, set):Bool = true;
	public var locked(default, set):Bool = false;
	public var cursor(default, set):MouseCursor = Default;

	@:signal public function exited();

	@:signal public function scrolled(delta:Int);

	@:signal public function moved(x:Int, y:Int, dx:Int, dy:Int);

	@:signal public function pressed(button:MouseButton, x:Int, y:Int);

	@:signal public function released(button:MouseButton, x:Int, y:Int);

	@:signal public function hold(button:MouseButton, x:Int, y:Int);

	@:signal public function clicked(button:MouseButton, x:Int, y:Int);

	@:signal public function doubleClicked(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonPressed(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonReleased(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonHold(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonClicked(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonDoubleClicked(button:MouseButton, x:Int, y:Int);

	public function new(id:Int = 0) {
		mouse = kha.input.Mouse.get(id);
		mouse.notify((b, x, y) -> pressed(b, x, y), (b, x, y) -> released(b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy), d -> scrolled(d), () -> exited());

		onPressed((b, x, y) -> buttonPressed(b, x, y));
		onReleased((b, x, y) -> buttonReleased(b, x, y));
		onHold((b, x, y) -> buttonHold(b, x, y));
		onClicked((b, x, y) -> buttonClicked(b, x, y));
		onDoubleClicked((b, x, y) -> buttonDoubleClicked(b, x, y));
	}

	@:slot(pressed)
	function __syncPressed__(button:MouseButton, x:Int, y:Int) {
		buttonsDown.push(button);

		recentlyPressed.set(button, Timer.set(() -> {
			recentlyPressed.remove(button);
		}, clickInterval));
		buttonHoldTimers.set(button, Timer.set(() -> {
			if (buttonHoldTimers.exists(button))
				hold(button, this.x, this.y);
		}, holdInterval));
	}

	@:slot(released)
	function __syncReleased__(button:MouseButton, x:Int, y:Int) {
		if (recentlyPressed.exists(button))
			clicked(button, x, y);

		buttonHoldTimers.get(button)?.stop();
		buttonHoldTimers.remove(button);
		buttonsDown.remove(button);
	}

	@:slot(clicked)
	function __syncClicked__(button:MouseButton, x:Int, y:Int) {
		if (recentlyClicked.exists(button))
			doubleClicked(button, x, y);

		recentlyClicked.set(button, Timer.set(() -> recentlyClicked.remove(button), doubleClickInterval));
	}

	@:slot(exited)
	function __syncExited__() {
		recentlyPressed.clear();
		buttonHoldTimers.clear();
	}

	@:slot(moved)
	function __syncMoved__(x:Int, y:Int, dx:Int, dy:Int) {
		this.x = x;
		this.y = y;
	}

	function set_visible(value:Bool):Bool {
		if (visible = value)
			mouse.showSystemCursor();
		else
			mouse.hideSystemCursor();
		return visible;
	}

	function set_locked(value:Bool):Bool {
		if (locked = value)
			mouse.lock();
		else
			mouse.unlock();
		return locked;
	}

	function set_cursor(value:MouseCursor):MouseCursor {
		mouse.setSystemCursor(value);
		return cursor = value;
	}
}
