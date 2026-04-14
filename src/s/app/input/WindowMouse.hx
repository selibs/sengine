package s.app.input;

class WindowMouse extends Mouse {
	public final windowId:Int;

	public function new(windowId:Int = 0, id:Int = 0) {
		this.windowId = windowId;
		super(id);
	}

	override function connect()
		mouse.notifyWindowed(windowId, (b, x, y) -> down(b, x, y), (b, x, y) -> up(b, x, y), (x, y, dx, dy) -> moved(x, y, dx, dy), d -> scrolled(d),
			() -> exited());
}
