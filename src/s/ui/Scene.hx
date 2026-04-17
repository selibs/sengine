package s.ui;

import s.app.Time;
import s.app.Window;
import s.app.input.Mouse;
import s.math.Mat3;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;
import s.ui.elements.Drawable;
import s.ui.elements.Interactive;

@:allow(s.ui.Element)
@:access(s.ObjectList)
@:access(s.app.Window)
class Scene implements s.shortcut.Shortcut extends Element {
	final window:Window;

	final drawable:Array<Drawable> = [];
	final interactive:Array<Interactive> = [];

	final active:Array<Interactive> = [];

	public var color:Color = White;
	public var focus(default, set):Interactive;

	@:signal public static function resized(width:Int, height:Int):Void;

	public function new(window:Window) {
		super();
		scene = this;

		this.window = window;
		App.onUpdate(render);

		window.onResized(resize);
		window.mouse.onMoved(processMouseMoved);
		window.mouse.onScrolled(processMouseScrolled);
		window.mouse.onDown(processMouseDown);
		window.mouse.onUp(processMouseUp);

		var k = App.input.keyboard;
		k.onDown(k -> if (k == Tab) adjustFocus(1, TabFocus));
		k.onDown(key -> focus?.keyboardDown(key));
		k.onUp(key -> focus?.keyboardUp(key));
		k.onHold(key -> focus?.keyboardHold(key));
		k.onPressed(char -> focus?.keyboardPressed(char));

		resize(window.width, window.height);
	}

	function resize(width:Int, height:Int) {
		this.width = width;
		this.height = height;

		final t = window.backbuffer.context2D.transform;
		final i = kha.Image.renderTargetsInvertedY();
		t.setFrom(i ? Mat3.orthogonalProjection(0.0, width, 0.0, height) : Mat3.orthogonalProjection(0.0, width, height, 0.0));
	}

	function adjustFocus(d:Int, policy:FocusPolicy) {
		var ind = interactive.indexOf(focus);
		if (ind >= 0)
			ind = (ind + d) % interactive.length;
		else
			ind = 0;
		for (i in ind...interactive.length) {
			final el = interactive[i];
			if (el.isEnabled && el.focusPolicy & policy != 0) {
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
			if (el.isEnabled) {
				final containsMouse = el.covers(x, y);
				if (!active.contains(el)) {
					if (containsMouse) {
						active.push(el);
						el.mouseEntered(x, y); // TODO: local space
					}
				} else {
					if (!containsMouse) {
						active.remove(el);
						el.mouseExited(x, y); // TODO: local space
					} else if (!m.accepted)
						el.mouseMoved(m); // TODO: local space
				}
			}
	}

	function processMouseDown(b:MouseButton, x:Int, y:Int):Void
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> if (c.acceptedButtons & b != 0) c.mouseDown(m));

	function processMouseUp(b:MouseButton, x:Int, y:Int):Void
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> if (c.acceptedButtons & b != 0) c.mouseUp(m));

	function processMouseScrolled(d:Int):Void {
		processMouseEvent({
			accepted: false,
			delta: d,
			x: s.App.input.mouse.x,
			y: s.App.input.mouse.y
		}, (c, m) -> c.mouseScrolled(m));
		adjustFocus(d, WheelFocus);
	}

	inline function processMouseEvent<T:MouseEvent>(m:T, f:(Interactive, T) -> Void)
		for (el in active)
			if (el.isEnabled) {
				f(el, m); // TODO: local space
				if (m.accepted)
					break;
			}

	function set_focus(value:Interactive):Interactive {
		if (focus == value)
			return focus;
		if (focus != null)
			@:bypassAccessor focus.isFocused = false;
		if (value != null)
			@:bypassAccessor value.isFocused = true;
		return focus = value;
	}

	function render() {
		if (dirty || children.dirty) {
			if (children.dirty) {
				drawable.resize(0);
				interactive.resize(0);
			}
			updateTree();
			interactive.reverse();
		}

		final ctx = window.backbuffer.context2D;
		ctx.begin();
		ctx.clear(color);

		for (el in drawable)
			el.draw(window.backbuffer);

		#if debug_element_bounds
		if (window.mouse.hovers)
			descendantAt(window.mouse.x, window.mouse.y)?.drawBounds(ctx);
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
		ctx.style.font.family = "default";
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
}
