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

#if !macro
@:build(se.macro.SMacro.build())
#end
class Mouse {
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

	@:signal function exited();

	@:signal function scrolled(delta:Int);

	@:signal function moved(x:Int, y:Int, dx:Int, dy:Int);

	@:signal function pressed(button:MouseButton, x:Int, y:Int);

	@:signal function released(button:MouseButton, x:Int, y:Int);

	@:signal function hold(button:MouseButton, x:Int, y:Int);

	@:signal function clicked(button:MouseButton, x:Int, y:Int);

	@:signal function doubleClicked(button:MouseButton, x:Int, y:Int);

	public function new(id:Int = 0) {
		mouse = kha.input.Mouse.get(id);
		mouse.notify(pressed.emit, released.emit, moved.emit, scrolled.emit, exited.emit);
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
