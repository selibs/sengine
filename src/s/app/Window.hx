package s.app;

import kha.WindowMode;
import kha.WindowOptions;
import kha.FramebufferOptions;
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
	public static inline function create(?win:WindowOptions, ?frame:FramebufferOptions)
		return new Window(KhaWindow.create(win, frame));

	var window:KhaWindow;
	var backbuffer:RenderTarget;

	/** Window title. */
	@:alias public var title:String = window.title;

	/** Current window mode. */
	@:alias public var mode:WindowMode = window.mode;

	/** Current window visibility. */
	@:alias public var visible:Bool = window.visible;

	/** Window X position in screen coordinates. */
	@:alias public var x:Int = window.x;

	/** Window Y position in screen coordinates. */
	@:alias public var y:Int = window.y;

	/**
	 * Window width in pixels.
	 */
	@:readonly @:alias public var width:Int = window.width;

	/**
	 * Window height in pixels.
	 */
	@:readonly @:alias public var height:Int = window.height;

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
	@:signal public function render();

	@:access(s.App)
	function new(w:KhaWindow) {
		window = w;

		backbuffer = new RenderTarget(width, height);
		backbuffer.generateMipmaps(1);
		App.windows.push(this);

		window.notifyOnResize((w, h) -> {
			backbuffer.unload();
			backbuffer = new RenderTarget(w, h);
			backbuffer.generateMipmaps(1);
			resized(w, h);
		});
	}

	/**
	 * Moves the window.
	 *
	 * @param x New X position.
	 * @param y New Y position.
	 */
	public inline function move(x:Int, y:Int)
		window.move(x, y);

	/**
	 * Resizes the window.
	 *
	 * This requests a new platform window size. The actual current size becomes
	 * visible through [`width`](s.app.Window.width) and [`height`](s.app.Window.height)
	 * after the resize callback is received.
	 *
	 * @param width New width in pixels.
	 * @param height New height in pixels.
	 */
	public inline function resize(width:Int, height:Int)
		window.resize(width, height);

	/** Destroys the underlying platform window. */
	public inline function destroy()
		KhaWindow.destroy(window);

	function syncFramebuffer()
		window.changeFramebuffer({
			frequency: frequency,
			verticalSync: verticalSync,
			colorBufferBits: colorBufferBits,
			depthBufferBits: depthBufferBits,
			stencilBufferBits: stencilBufferBits,
			samplesPerPixel: samplesPerPixel
		});

	function syncFeatures() {
		var top = onTop ? FeatureOnTop : None;
		var res = resizable ? FeatureResizable : None;
		var bor = borderless ? FeatureBorderless : None;
		var min = minimizable ? FeatureMinimizable : None;
		var max = maximizable ? FeatureMaximizable : None;
		window.changeWindowFeatures(res | min | max | bor | top);
	}
}
