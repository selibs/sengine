package s.app;

import kha.WindowMode;
import kha.WindowOptions;
import kha.FramebufferOptions;
import kha.Window as KhaWindow;
import s.Color;
import s.math.Mat3;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;
import s.graphics.RenderTarget;
import s.app.Time;
import s.app.input.Mouse;
import s.app.input.WindowMouse;
import s.ui.FocusPolicy;
import s.ui.elements.Element;
import s.ui.elements.DrawableElement;
import s.ui.elements.InteractiveElement;

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
@:access(s.ObjectList)
@:access(s.app.Window)
@:allow(s.ui.elements.Element)
@:access(s.ui.elements.Element)
class Window implements s.shortcut.Shortcut {
	public static inline function create(?win:WindowOptions, ?frame:FramebufferOptions)
		return new Window(KhaWindow.create(win, frame));

	final window:KhaWindow;
	final mouse:WindowMouse;
	var backbuffer:RenderTarget;

	final drawable:Array<DrawableElement> = [];
	final interactive:Array<InteractiveElement> = [];
	final active:Array<InteractiveElement> = [];

	public final id:Int;
	public final root:Element;
	public var focus(default, set):InteractiveElement;
	public var color:Color = White;

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

	@:access(s.App)
	function new(w:KhaWindow) {
		id = App.windows.push(this) - 1;
		window = w;
		window.notifyOnResize((w, h) -> resized(w, h));

		root = new Element();
		root.scene = this;
		backbuffer = new RenderTarget(width, height);

		mouse = new WindowMouse(id);
		mouse.onMoved(processMouseMoved);
		mouse.onScrolled(processMouseScrolled);
		mouse.onDown(processMouseDown);
		mouse.onUp(processMouseUp);

		var k = App.input.keyboard;
		k.onDown(k -> if (k == Tab) adjustFocus(1, TabFocus));
		k.onDown(key -> focus?.keyboardDown(key));
		k.onUp(key -> focus?.keyboardUp(key));
		k.onHold(key -> focus?.keyboardHold(key));
		k.onPressed(char -> focus?.keyboardPressed(char));

		processResized(width, height);
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

	@:slot(resized)
	function processResized(width:Int, height:Int) {
		root.width = width;
		root.height = height;

		backbuffer.unload();
		backbuffer = new RenderTarget(width, height);
		backbuffer.generateMipmaps(1);

		final t = backbuffer.context2D.transform;
		if (kha.Image.renderTargetsInvertedY())
			t.setFrom(Mat3.orthogonalProjection(0.0, width, 0.0, height));
		else
			t.setFrom(Mat3.orthogonalProjection(0.0, width, height, 0.0));
	}

	function render() {
		if (root.children.dirty) {
			drawable.resize(0);
			interactive.resize(0);
		}
		if (root.dirty || root.children.dirty)
			root.syncTree();

		final ctx = backbuffer.context2D;
		ctx.begin();
		ctx.clear(color);

		for (el in drawable)
			el.draw(backbuffer);

		#if debug_element_bounds
		if (mouse.hovers)
			root.descendantAt(mouse.x, mouse.y)?.drawBounds(ctx);
		#end

		#if debug
		drawDebugInfo(ctx);
		Context3D.resetDebugInfo();
		#end

		ctx.end();
	}

	#if debug
	function drawDebugInfo(ctx:Context2D) {
		ctx.style.font.setDefault();
		ctx.style.font.family = "font_default";
		ctx.style.font.pixelSize = 14;

		final time = Time.delta;
		final fps = Std.int(1.0 / time);
		var offset = 5;

		inline function draw(text:String) {
			ctx.style.color = Black;
			ctx.drawString(text, 6, offset + 1);
			ctx.style.color = White;
			ctx.drawString(text, 5, offset);
			offset += 16;
		}

		draw("FPS: " + fps);
		draw("Frame (ms): " + roundTo(time * 1000, 1));
		// draw("CPU (ms): " + roundTo(Context3D.cpuTime, 1));
		// draw("GPU (ms): " + roundTo(Context3D.gpuTime, 1));
		draw("Draw calls: " + Context3D.drawCalls);
		draw("IB allocations: " + Context3D.ibAllocations);
		draw("VB allocations: " + Context3D.vbAllocations);
	}
	#end

	function adjustFocus(d:Int, policy:FocusPolicy) {
		var ind = interactive.indexOf(focus);
		if (ind >= 0)
			ind = (ind + d) % interactive.length;
		else
			ind = 0;
		for (i in ind...interactive.length) {
			final el = interactive[i];
			if (el.enabled && el.focusPolicy & policy != 0) {
				focus = el;
				break;
			}
		}
	}

	function processMouseMoved(x:Int, y:Int, dx:Int, dy:Int):Void {
		final m = {
			accepted: false,
			x: x,
			y: y,
			dx: dx,
			dy: dy
		}

		for (el in interactive)
			if (el.enabled) {
				final containsMouse = el.covers(x, y);
				if (!active.contains(el)) {
					if (containsMouse) {
						active.push(el);
						el.hovered = true;
						el.mouseEntered(x, y); // TODO: local space
					}
				} else {
					if (!containsMouse) {
						active.remove(el);
						el.hovered = false;
						el.mouseExited(x, y); // TODO: local space
					} else if (!m.accepted)
						el.mouseMoved(m); // TODO: local space
				}
			}
	}

	function processMouseScrolled(d:Int):Void {
		processMouseEvent({
			accepted: false,
			delta: d,
			x: s.App.input.mouse.x,
			y: s.App.input.mouse.y
		}, (c, m) -> c.mouseScrolled(m));
		adjustFocus(d, WheelFocus);
	}

	function processMouseDown(b:MouseButton, x:Int, y:Int):Void
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> c.mouseDown(m));

	function processMouseUp(b:MouseButton, x:Int, y:Int):Void
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> c.mouseUp(m));

	inline function processMouseEvent<T:MouseEvent>(m:T, f:(InteractiveElement, T) -> Void)
		for (el in active)
			if (el.enabled) {
				f(el, m); // TODO: local space
				if (m.accepted)
					break;
			}

	function set_focus(value:InteractiveElement):InteractiveElement {
		if (focus == value)
			return focus;
		if (focus != null)
			@:bypassAccessor focus.focused = false;
		if (value != null)
			@:bypassAccessor value.focused = true;
		return focus = value;
	}

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
