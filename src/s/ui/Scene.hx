package s.ui;

import kha.Framebuffer;
import s.app.Time;
import s.app.Window;
import s.app.input.MouseButton;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;
import s.graphics.RenderTarget;
import s.ui.FocusPolicy;
import s.ui.elements.Layer;
import s.ui.elements.Interactive;

@:allow(s.ui.Element)
@:access(s.ObjectList)
@:access(s.app.Window)
class Scene implements s.shortcut.Shortcut extends Layer {
	final window:Window;

	final interactive:Array<Interactive> = [];

	final hovered:Array<Interactive> = [];
	final pressed:Array<Interactive> = [];

	public var focus(default, set):Interactive = null;

	public function new(window:Window) {
		super();

		@:bypassAccessor scene = this;
		@:bypassAccessor layer = this;

		this.window = window;
		this.width = window.width;
		this.height = window.height;

		App.onUpdate(() -> updateTree());
		window.onRender(render);

		var m = window.mouse;
		m.onMoved(processMouseMoved);
		m.onScrolled(processMouseScrolled);
		m.onPressed(processMousePressed);
		m.onReleased(processMouseReleased);

		var k = App.input.keyboard;
		k.onShortcut("Tab", () -> adjustFocus(1, TabFocus));

		k.onPressed(key -> if (focus?.isEnabled) focus.keyboardPressed(key));
		k.onReleased(key -> if (focus?.isEnabled) focus.keyboardReleased(key));
		k.onHold(key -> if (focus?.isEnabled) focus.keyboardHold(key));
		k.onTyped(char -> if (focus?.isEnabled) focus.keyboardTyped(char));
		k.onHotkey(hotkey -> if (focus?.isEnabled) focus.keyboardHotkey(hotkey));
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

	override function update() {
		if (width != window.width)
			width = window.width;
		if (height != window.height)
			height = window.height;

		super.update();

		if (children.dirty)
			interactive.resize(0);
	}

	override function updateTree(?styles:Array<Style>, inheritedDirty:Bool = false) {
		super.updateTree(styles, inheritedDirty);
		if (children.dirty)
			interactive.reverse();
	}

	override function draw(target:RenderTarget) {
		final ctx = target.context2D;
		ctx.begin();
		ctx.clear(color);
		ctx.style.color = White;
		ctx.drawImage(texture, 0, 0);

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

	function render(framebuffer:Framebuffer) {
		final g2 = framebuffer.g2;

		g2.begin(color);
		g2.drawImage(texture, 0, 0);
		g2.end();
	}

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
