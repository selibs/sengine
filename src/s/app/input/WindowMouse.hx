package s.app.input;

class WindowMouse extends Mouse {
	public final windowId:Int;

	public var hovers(default, null):Bool = false;

	@:signal public function entered();

	@:signal public function exited();

	public function new(windowId:Int = 0, id:Int = 0) {
		this.windowId = windowId;
		super(id);
	}

	override function connect()
		mouse.notifyWindowed(windowId, (b, x, y) -> pressed(1 << b, x, y), (b, x, y) -> released(1 << b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy),
			d -> scrolled(d), () -> exited());

	override function updateMoved(x:Int, y:Int, dx:Int, dy:Int) {
		super.updateMoved(x, y, dx, dy);
		if (!hovers)
			entered();
	}

	@:slot(entered)
	function updateEntered()
		hovers = true;

	@:slot(exited)
	function updateExited()
		hovers = false;
}
