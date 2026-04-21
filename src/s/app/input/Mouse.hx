package s.app.input;

class Mouse implements s.shortcut.Shortcut {
	var mouse:kha.input.Mouse;

	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;

	public var isLocked(get, set):Bool;
	public var isVisible(default, set):Bool = true;
	public var cursor(default, set):MouseCursor = Default;

	@:signal public function pressed(button:MouseButton, x:Int, y:Int);

	@:signal public function released(button:MouseButton, x:Int, y:Int);

	@:signal public function moved(x:Int, y:Int, dx:Int, dy:Int);

	@:signal public function scrolled(delta:Int);

	@:signal(button) public function buttonPressed(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonReleased(button:MouseButton, x:Int, y:Int);

	public function new(id:Int = 0) {
		mouse = kha.input.Mouse.get(id);
		connect();

		onPressed((b, x, y) -> buttonPressed(b, x, y));
		onReleased((b, x, y) -> buttonReleased(b, x, y));
	}

	function connect()
		mouse.notify((b, x, y) -> pressed(1 << b, x, y), (b, x, y) -> released(1 << b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy), d -> scrolled(d));

	@:slot(moved)
	function updateMoved(x:Int, y:Int, dx:Int, dy:Int) {
		this.x = x;
		this.y = y;
	}

	@:slot(pressed)
	function updatePressed(b:MouseButton, x:Int, y:Int)
		buttonPressed(b, x, y);

	@:slot(released)
	function updateReleased(b:MouseButton, x:Int, y:Int)
		buttonReleased(b, x, y);

	function set_isVisible(value:Bool):Bool {
		if (isVisible = value)
			mouse.showSystemCursor();
		else
			mouse.hideSystemCursor();
		return isVisible;
	}

	function get_isLocked():Bool
		return mouse.isLocked();

	function set_isLocked(value:Bool):Bool {
		if (value && isLocked)
			mouse.unlock();
		else if (mouse.canLock())
			mouse.lock();
		return isLocked;
	}

	function set_cursor(value:MouseCursor):MouseCursor {
		mouse.setSystemCursor(value);
		return cursor = value;
	}
}
