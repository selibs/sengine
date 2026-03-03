package se.system;

import kha.WindowMode;
import kha.WindowOptions;
import kha.Window as KhaWindow;
import kha.Framebuffer;
import se.system.input.Mouse;
import s2d.FocusPolicy;
import s2d.Element;
import s2d.WindowScene;

#if !macro
@:build(se.macro.SMacro.build())
#end
final class Window {
	public static function create():Window {
		return new Window(KhaWindow.create());
	}

	var window:KhaWindow;
	var backbuffer:Texture;

	var pending:Array<Element> = [];
	var entered:Array<Element> = [];
	@:isVar var focusedElement(default, set):Element;

	@:isVar public var scene(default, set):WindowScene;
	@:isVar public var overlay(default, set):Element;

	@alias public var title:String = window.title;
	@alias public var mode:WindowMode = window.mode;
	@alias public var x:Int = window.x;
	@alias public var y:Int = window.y;
	@alias public var width:Int = window.width;
	@alias public var height:Int = window.height;

	@:inject(syncFeatures) public var resizable:Bool = true;
	@:inject(syncFeatures) public var minimizable:Bool = true;
	@:inject(syncFeatures) public var maximizable:Bool = true;
	@:inject(syncFeatures) public var borderless:Bool = false;
	@:inject(syncFeatures) public var onTop:Bool = false;

	@:inject(syncFramebuffer) public var frequency:Int = 60;
	@:inject(syncFramebuffer) public var verticalSync:Bool = true;
	@:inject(syncFramebuffer) public var colorBufferBits:Int = 32;
	@:inject(syncFramebuffer) public var depthBufferBits:Int = 16;
	@:inject(syncFramebuffer) public var stencilBufferBits:Int = 8;
	@:inject(syncFramebuffer) public var samplesPerPixel:Int = 1;

	@:signal function resized(width:Int, height:Int);

	public function new(window:KhaWindow) {
		this.window = window;

		backbuffer = new Texture(width, height);

		window.notifyOnResize((w, h) -> {
			backbuffer?.unload();
			backbuffer = new Texture(w, h);
			if (scene != null) {
				scene.width = w;
				scene.height = h;
			}
			if (overlay != null) {
				overlay.width = w;
				overlay.height = h;
			}
			resized(w, h);
		});

		// handle mouse events
		var m = App.input.mouse;
		m.onMoved(processMouseMoved);
		m.onScrolled(d -> {
			processMouseScrolled(d, m.x, m.y);
			adjustWheelFocus(d);
		});
		m.onPressed(processMouseDown);
		m.onReleased(processMouseUp);
		m.onHold(processMouseHold);
		m.onClicked(processMouseClicked);
		m.onDoubleClicked(processMouseDoubleClicked);

		// handle keyboard events
		var k = App.input.keyboard;
		k.onKeyDown(Tab, adjustTabFocus);
		k.onDown(key -> focusedElement?.keyboardDown(key));
		k.onUp(key -> focusedElement?.keyboardUp(key));
		k.onHold(key -> focusedElement?.keyboardHold(key));
		k.onPressed(char -> focusedElement?.keyboardPressed(char));
	}

	public function resize(width:Int, height:Int) {
		window.resize(width, height);
	}

	public function destroy() {
		KhaWindow.destroy(window);
	}

	function render(frame:Framebuffer) @:privateAccess {
		backbuffer.context2D.render(true, scene?.color ?? Black, ctx -> {
			scene?.render(backbuffer);
			overlay?.render(backbuffer);
		});

		final g2 = frame.g2;
		g2.begin(true);
		g2.drawImage(backbuffer, 0, 0);
		g2.end();
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
		var res = resizable ? FeatureResizable : None;
		var min = minimizable ? FeatureMinimizable : None;
		var max = maximizable ? FeatureMaximizable : None;
		var bor = borderless ? FeatureBorderless : None;
		var top = onTop ? FeatureOnTop : None;
		window.changeWindowFeatures(res | min | max | bor | top);
	}

	function adjustTabFocus() {
		if (scene != null) {
			final i = scene.children.indexOf(focusedElement);
			for (j in 1...scene.children.length) {
				var e = scene.children[(i + j) % scene.children.length];
				if (e.enabled && (e.focusPolicy & TabFocus != 0)) {
					focusedElement = e;
					return;
				}
			}
		}
	}

	function adjustWheelFocus(d:Int) {
		if (scene != null) {
			final i = scene.children.length + scene.children.indexOf(focusedElement);
			for (j in 1...scene.children.length) {
				var e = scene.children[(i + (d > 0 ? j : -j)) % scene.children.length];
				if (e.enabled && (e.focusPolicy & WheelFocus != 0)) {
					focusedElement = e;
					return;
				}
			}
		}
	}

	function processMouseMoved(x:Int, y:Int, dx:Int, dy:Int):Void {
		var containsMouse = [];
		processMouseEvent({
			accepted: false,
			x: x,
			y: y,
			dx: dx,
			dy: dy
		}, (c, m) -> {
			containsMouse.push(c);
			if (!entered.contains(c)) {
				entered.push(c);
				c.mouseEntered(x, y);
			}
			c.mouseMoved(m);
		});
		for (c in entered)
			if (!containsMouse.contains(c)) {
				entered.remove(c);
				c.mouseExited(x, y);
			}
	}

	function processMouseScrolled(d:Int, x:Int, y:Int):Void {
		processMouseEvent({
			accepted: false,
			delta: d,
			x: x,
			y: y
		}, (c, m) -> c.mouseScrolled(m));
	}

	function processMouseDown(b:MouseButton, x:Int, y:Int):Void {
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> {
			pending.push(c);
			c.mousePressed(m);
		});
	}

	function processMouseUp(b:MouseButton, x:Int, y:Int):Void {
		final m = {
			accepted: false,
			button: b,
			x: x,
			y: y
		}
		for (el in pending)
			el.mouseReleased(m);
	}

	function processMouseHold(b:MouseButton, x:Int, y:Int):Void {
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> c.mouseHold(m));
	}

	function processMouseClicked(b:MouseButton, x:Int, y:Int):Void {
		var focusedSet = false;
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> {
			c.mouseClicked(m);
			if (!focusedSet && (c.focusPolicy & ClickFocus != 0)) {
				focusedSet = true;
				focusedElement = c;
			}
		});
	}

	function processMouseDoubleClicked(b:MouseButton, x:Int, y:Int):Void {
		processMouseEvent({
			accepted: false,
			button: b,
			x: x,
			y: y
		}, (c, m) -> c.mouseDoubleClicked(m));
	}

	function processMouseEvent<T:MouseEvent>(m:T, f:(Element, T) -> Void) {
		function process(els:Array<Element>) {
			var i = 0;
			while (++i <= els.length) {
				var el = els[els.length - i];
				if (el.enabled && el.visible) {
					process(el.children);
					if (m.accepted)
						return;
					if (el.contains(m.x, m.y)) {
						f(el, m);
						if (m.accepted)
							return;
					}
				}
			}
		}
		if (scene != null)
			process(scene.children);
	}

	function set_scene(value:WindowScene):WindowScene {
		if (value != scene && value.window == this) {
			final old = scene;
			scene = value;
			old?.unset();
			if (scene != null) {
				scene.width = width;
				scene.height = height;
				scene.set();
			}
		}
		return scene;
	}

	function set_overlay(value:Element):Element {
		overlay = value;
		if (overlay != null) {
			overlay.width = width;
			overlay.height = height;
		}
		return overlay;
	}

	function set_focusedElement(value:Element):Element {
		if (focusedElement != value) {
			if (focusedElement != null)
				focusedElement.focused = false;
			value.focused = true;
			focusedElement = value;
		}
		return focusedElement;
	}
}
