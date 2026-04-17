package s.app.input;

typedef MouseCursor = kha.input.Mouse.MouseCursor;

extern enum abstract MouseButton(Int) from Int to Int {
	var Left = 1 << 0;
	var Right = 1 << 1;
	var Middle = 1 << 2;
	var Back = 1 << 3;
	var Forward = 1 << 4;
	var All = Left | Right | Middle | Back | Forward;

	@:to
	public inline function toString():String
		return switch this {
			case Left: "Left";
			case Right: "Right";
			case Middle: "Middle";
			case Back: "Back";
			case Forward: "Forward";
			default: 'MouseButton(${(this : Int)})';
		}
}

class Mouse implements s.shortcut.Shortcut {
	var mouse:kha.input.Mouse;

	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var hovers(default, null):Bool = false;

	public var isLocked(get, set):Bool;
	public var isVisible(default, set):Bool = true;
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
		connect();

		onDown((b, x, y) -> buttonDown(b, x, y));
		onUp((b, x, y) -> buttonUp(b, x, y));
	}

	function connect()
		mouse.notify((b, x, y) -> down(1 << b, x, y), (b, x, y) -> up(1 << b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy), d -> scrolled(d), () -> exited());

	@:slot(moved)
	function updateMoved(x:Int, y:Int, dx:Int, dy:Int) {
		this.x = x;
		this.y = y;
		if (!hovers)
			entered();
	}

	@:slot(down)
	function updateDown(b:MouseButton, x:Int, y:Int)
		buttonDown(b, x, y);

	@:slot(down)
	function updateUp(b:MouseButton, x:Int, y:Int)
		buttonUp(b, x, y);

	@:slot(entered)
	function updateEntered()
		hovers = true;

	@:slot(exited)
	function updateExited()
		hovers = false;

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
