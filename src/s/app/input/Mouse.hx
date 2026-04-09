package s.app.input;

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

	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var hovers(default, null):Bool = false;

	public var locked(get, set):Bool;
	public var visible(default, set):Bool = true;
	public var cursor(default, set):MouseCursor = Default;

	@:signal public function entered();

	@:signal public function exited();

	@:signal public function scrolled(delta:Int);

	@:signal public function moved(x:Int, y:Int, dx:Int, dy:Int);

	@:signal public function down(button:MouseButton, x:Int, y:Int);

	@:signal public function up(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonDown(button:MouseButton, x:Int, y:Int);

	@:signal(button) public function buttonUp(button:MouseButton, x:Int, y:Int);

	public function new(id:Int = 0) {
		mouse = kha.input.Mouse.get(id);
		mouse.notify((b, x, y) -> down(b, x, y), (b, x, y) -> up(b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy), d -> scrolled(d), () -> exited());

		onDown((b, x, y) -> buttonDown(b, x, y));
		onUp((b, x, y) -> buttonUp(b, x, y));
	}

	@:slot(moved)
	function syncMoved(x:Int, y:Int, dx:Int, dy:Int) {
		this.x = x;
		this.y = y;
		if (!hovers)
			entered();
	}

	@:slot(down)
	function syncDown(b:MouseButton, x:Int, y:Int)
		buttonDown(b, x, y);

	@:slot(down)
	function syncUp(b:MouseButton, x:Int, y:Int)
		buttonUp(b, x, y);

	@:slot(entered)
	function syncEntered()
		hovers = true;

	@:slot(exited)
	function syncExited()
		hovers = false;

	function set_visible(value:Bool):Bool {
		if (visible = value)
			mouse.showSystemCursor();
		else
			mouse.hideSystemCursor();
		return visible;
	}

	function get_locked():Bool
		return mouse.isLocked();

	function set_locked(value:Bool):Bool {
		if (locked)
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
