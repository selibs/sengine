package s;

import kha.WindowMode;
import kha.WindowOptions;
import kha.Window as KhaWindow;
import s.graphics.RenderTarget;

/**
 * Runtime window wrapper with framebuffer configuration and render signals.
 *
 * `Window` exposes the platform window as a higher-level engine object. It keeps
 * the current back buffer, mirrors platform window properties, and emits a
 * render signal every frame with the texture that should be drawn into.
 *
 * Most applications configure the initial window inside the `setup` callback
 * passed to [`App.start`](s.App.start).
 */
@:allow(s.App)
class Window implements s.shortcut.Shortcut {
	var backBuffer:RenderTarget;
	var window:KhaWindow;

	/** Window X position in screen coordinates. */
	@:alias public var x:Int = window.x;

	/** Window Y position in screen coordinates. */
	@:alias public var y:Int = window.y;

	/**
	 * Current window width in pixels.
	 *
	 * This is updated from platform resize notifications and should be treated as
	 * informational state, not as a writable requested size.
	 */
	public var width(default, null):Int = 0;

	/**
	 * Current window height in pixels.
	 *
	 * This is updated from platform resize notifications and should be treated as
	 * informational state, not as a writable requested size.
	 */
	public var height(default, null):Int = 0;

	/** Window title. */
	@:alias public var title:String = window.title;

	/** Current window mode. */
	@:alias public var mode:WindowMode = window.mode;

	/**
	 * Whether the active framebuffer is synchronized to vertical refresh.
	 *
	 * This reflects the state of the underlying window framebuffer after it has
	 * been configured.
	 */
	@:readonly @:alias public var vSynced:Bool = window.vSynced;

	/** Whether the window should stay on top. */
	@:inject(syncFeatures) public var onTop:Bool = false;

	/** Whether the user can resize the window. */
	@:inject(syncFeatures) public var resizable:Bool = true;

	/** Whether the window should be borderless. */
	@:inject(syncFeatures) public var borderless:Bool = false;

	/** Whether the window can be minimized. */
	@:inject(syncFeatures) public var minimizable:Bool = true;

	/** Whether the window can be maximized. */
	@:inject(syncFeatures) public var maximizable:Bool = true;

	/**
	 * Preferred refresh frequency for the framebuffer.
	 *
	 * This participates in framebuffer reconfiguration and does not directly move
	 * the OS window to another display mode by itself.
	 */
	@:inject(syncFramebuffer) public var frequency:Int = 60;

	/** Whether framebuffer presentation should use vertical sync. */
	@:inject(syncFramebuffer) public var verticalSync:Bool = true;

	/** Color buffer bit depth. */
	@:inject(syncFramebuffer) public var colorBufferBits:Int = 32;

	/** Depth buffer bit depth. */
	@:inject(syncFramebuffer) public var depthBufferBits:Int = 16;

	/** Stencil buffer bit depth. */
	@:inject(syncFramebuffer) public var stencilBufferBits:Int = 8;

	/** Multisample count. */
	@:inject(syncFramebuffer) public var samplesPerPixel:Int = 1;

	/**
	 * Fired after the window size changes.
	 *
	 * The back buffer has already been recreated when this signal runs.
	 */
	@:signal public function resized(width:Int, height:Int);

	/**
	 * Fired every frame with the window back buffer as the render target.
	 *
	 * Rendering code should draw into the provided texture rather than directly to
	 * the platform framebuffer.
	 */
	@:signal public function render(target:RenderTarget);

	@:access(s.App)
	/**
	 * Creates a window wrapper around a Kha window.
	 *
	 * This constructor is called internally by the engine during startup.
	 *
	 * @param w Source Kha window.
	 */
	public function new(w:KhaWindow) {
		window = w;
		width = w.width;
		height = w.height;
		backBuffer = new RenderTarget(width, height);
		App.windows.push(this);

		window.notifyOnResize((w, h) -> {
			width = w;
			height = h;
			backBuffer.unload();
			backBuffer = new RenderTarget(width, height);
			resized(w, h);
		});
	}

	/**
	 * Moves the window.
	 *
	 * @param x New X position.
	 * @param y New Y position.
	 */
	public inline function move(x:Int, y:Int) {
		window.move(x, y);
	}

	/**
	 * Resizes the window.
	 *
	 * This requests a new platform window size. The actual current size becomes
	 * visible through [`width`](s.Window.width) and [`height`](s.Window.height)
	 * after the resize callback is received.
	 *
	 * @param width New width in pixels.
	 * @param height New height in pixels.
	 */
	public inline function resize(width:Int, height:Int) {
		window.resize(width, height);
	}

	/** Destroys the underlying platform window. */
	public inline function destroy() {
		KhaWindow.destroy(window);
	}

	function syncFramebuffer() {
		window.changeFramebuffer({
			frequency: frequency,
			verticalSync: verticalSync,
			colorBufferBits: colorBufferBits,
			depthBufferBits: depthBufferBits,
			stencilBufferBits: stencilBufferBits,
			samplesPerPixel: samplesPerPixel
		});
	}

	function syncFeatures() {
		var top = onTop ? FeatureOnTop : None;
		var res = resizable ? FeatureResizable : None;
		var bor = borderless ? FeatureBorderless : None;
		var min = minimizable ? FeatureMinimizable : None;
		var max = maximizable ? FeatureMaximizable : None;
		window.changeWindowFeatures(res | min | max | bor | top);
	}
}
