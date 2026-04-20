package s.ui;

import s.app.Time;
import s.app.Window;
import s.app.input.MouseButton;
import s.math.Mat3;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;
import s.graphics.RenderTarget;
import s.ui.FocusPolicy;
import s.ui.elements.Drawable;
import s.ui.elements.Interactive;

@:allow(s.ui.Element)
@:access(s.ObjectList)
@:access(s.app.Window)
class Scene implements s.shortcut.Shortcut extends Drawable {
	final window:Window;

	final drawable:Array<Drawable> = [];
	final interactive:Array<Interactive> = [];

	final hovered:Array<Interactive> = [];
	final pressed:Array<Interactive> = [];

	public var focus(default, set):Interactive = null;

	@:signal public static function resized(width:Int, height:Int):Void;

	public function new(window:Window) {
		super();
		scene = this;

		this.window = window;

		App.onUpdate(render);

		window.onResized(resize);
		window.mouse.onMoved(processMouseMoved);
		window.mouse.onScrolled(processMouseScrolled);
		window.mouse.onPressed(processMousePressed);
		window.mouse.onReleased(processMouseReleased);

		var k = App.input.keyboard;
		k.onShortcut("Tab", () -> adjustFocus(1, TabFocus));

		k.onPressed(key -> if (focus?.isEnabled) focus.keyboardPressed(key));
		k.onReleased(key -> if (focus?.isEnabled) focus.keyboardReleased(key));
		k.onHold(key -> if (focus?.isEnabled) focus.keyboardHold(key));
		k.onTyped(char -> if (focus?.isEnabled) focus.keyboardTyped(char));
		k.onHotkey(hotkey -> if (focus?.isEnabled) focus.keyboardHotkey(hotkey));

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
		if (interactive.length == 0) {
			focus = null;
			return;
		}

		var start = interactive.indexOf(focus);
		if (start < 0)
			start = d >= 0 ? 0 : interactive.length - 1;
		else
			start = (start + d + interactive.length) % interactive.length;

		for (step in 0...interactive.length) {
			final i = (start + step * (d >= 0 ? 1 : -1) + interactive.length) % interactive.length;
			final el = interactive[i];
			if (el.isEnabled && el.focusPolicy.matches(policy)) {
				focus = el;
				return;
			}
		}
	}

	function processMouseMoved(x:Int, y:Int, dx:Int, dy:Int):Void {
		for (el in interactive) {
			final c = el.covers(x, y);
			if (!hovered.contains(el)) {
				if (c && el.isEnabled) {
					hovered.push(el);
					final p = el.mapFromGlobal(x, y);
					el.enter(p.x, p.y);
				}
			} else {
				if (!c) {
					hovered.remove(el);
					final p = el.mapFromGlobal(x, y);
					el.exit(p.x, p.y);
				} else if (el.isEnabled) {
					final p = el.globalTransform * vec2(dx, dy);
					el.mouse(p.x, p.y);
				}
			}
		}
	}

	function processMousePressed(b:MouseButton, x:Int, y:Int):Void {
		var newFocus = null;
		for (el in hovered)
			if (el.isEnabled) {
				if (el.focusPolicy.matches(PointerFocus))
					newFocus = el;
				final p = el.mapFromGlobal(x, y);
				el.press(b, p.x, p.y);
				if (!el.propagateMouseEvents && el.acceptedButtons.matches(b))
					break;
			}
		focus = newFocus;
	}

	function processMouseReleased(b:MouseButton, x:Int, y:Int):Void
		for (el in pressed.copy()) {
			final p = el.mapFromGlobal(x, y);
			el.release(b, p.x, p.y);
		}

	function processMouseScrolled(d:Int):Void {
		adjustFocus(d, WheelFocus);
		for (el in hovered)
			if (el.isEnabled) {
				el.scroll(d);
				if (!el.propagateMouseEvents)
					break;
			}
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

		draw(window.backbuffer);
	}

	function draw(target:RenderTarget) {
		final ctx = target.context2D;
		ctx.begin();
		ctx.clear(color);

		for (el in drawable)
			el.draw(target);

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

	override function updateOrder() {}

	function set_focus(value:Interactive):Interactive {
		if (focus == value)
			return focus;
		if (focus != null) {
			@:bypassAccessor focus.isFocused = false;
			focus.isFocusedDirty = true;
		}
		if (value != null) {
			@:bypassAccessor value.isFocused = true;
			value.isFocusedDirty = true;
		}
		return focus = value;
	}
}
