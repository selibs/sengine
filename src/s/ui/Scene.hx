package s.ui;

import s.Color;
import s.app.Time;
import s.app.Window;
import s.app.input.Mouse;
import s.math.Mat3;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;
import s.graphics.RenderTarget;
import s.ui.elements.Element;
import s.ui.elements.DrawableElement;
import s.ui.elements.InteractiveElement;

@:access(s.app.Window)
@:allow(s.ui.elements.Element)
@:access(s.ui.elements.Element)
class Scene implements s.shortcut.Shortcut {
	@:readonly @:alias var target:RenderTarget = window.backbuffer;

	var drawable:Array<DrawableElement> = [];
	var drawableScratch:Array<DrawableElement> = [];
	var collectDrawables:Bool = false;
	final interactive:Array<InteractiveElement> = [];
	final active:Array<InteractiveElement> = [];

	public final window:Window;
	public final root:Element;
	public var focus(default, set):InteractiveElement;
	public var color:Color = White;

	public function new(win:Window) {
		root = new Element();
		root.scene = this;

		window = win;
		window.onResized(resize);
		window.onRender(render);
		resize(window.width, window.height);

		// mouse events
		var m = App.input.mouse;
		m.onMoved(processMouseMoved);
		m.onScrolled(processMouseScrolled);
		m.onDown(processMouseDown);
		m.onUp(processMouseUp);

		// // keyboard events
		// var k = App.input.keyboard;
		// k.onDown(k -> if (k == Tab) adjustTabFocus());
		// k.onDown(key -> focus?.keyboardDown(key));
		// k.onUp(key -> focus?.keyboardUp(key));
		// k.onHold(key -> focus?.keyboardHold(key));
		// k.onPressed(char -> focus?.keyboardPressed(char));
	}

	function resize(width:Int, height:Int) {
		root.width = width;
		root.height = height;

		if (kha.Image.renderTargetsInvertedY())
			target.context2D.transform = Mat3.orthogonalProjection(0.0, width, 0.0, height);
		else
			target.context2D.transform = Mat3.orthogonalProjection(0.0, width, height, 0.0);
	}

	@:access(s.app.Window)
	function render() {
		if (root.dirty) {
			collectDrawables = true;
			drawableScratch.resize(0);
			root.syncTree();
			collectDrawables = false;

			final rebuilt = drawableScratch;
			drawableScratch = drawable;
			drawable = rebuilt;
		}

		final ctx = target.context2D;
		ctx.begin();
		ctx.clear(color);

		for (el in drawable)
			el.draw(target);

		#if S2D_UI_DEBUG_ELEMENT_BOUNDS
		if (s.App.input.mouse.hovers)
			root.descendantAt(s.App.input.mouse.x, App.input.mouse.y)?.drawBounds(ctx);
		#end

		#if S2D_DEBUG_FPS
		drawDebugInfo(ctx);
		Context3D.resetDebugInfo();
		#end

		ctx.end();
	}

	#if S2D_DEBUG_FPS
	function drawDebugInfo(ctx:Context2D) {
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
}
