package s.ui;

import s.Time;
import s.Color;
import s.graphics.RenderTarget;
import s.Window;
import s.math.Mat3;
import s.math.SMath;
import s.graphics.Context2D;
import s.graphics.Context3D;

using s.extensions.StringExt;

@:allow(s.ui.Element)
class WindowScene implements s.shortcut.Shortcut {
	var projection:Mat3;

	static inline function createProjection(width:Int, height:Int):Mat3
		return kha.Image.renderTargetsInvertedY() ? Mat3.orthogonalProjection(0.0, width, 0.0, height) : Mat3.orthogonalProjection(0.0, width, height, 0.0);

	// var pending:Array<Element> = [];
	// var entered:Array<InteractiveElement> = [];
	// var focusedElement(default, set):Element;
	public var window(default, null):Window;
	public var root(default, set):Element;
	public var color:Color = White;

	public function new(w:Window) {
		window = w;
		window.onResized((width:Int, height:Int) -> {
			root.width = width;
			root.height = height;
			projection = createProjection(width, height);
		});
		window.onRender(render);

		root = new Element();
		projection = createProjection(window.width, window.height);

		// // mouse events
		// var m = App.input.mouse;
		// m.onMoved(processMouseMoved);
		// m.onScrolled(d -> {
		// 	processMouseScrolled(d, m.x, m.y);
		// 	adjustWheelFocus(d);
		// });
		// m.onPressed(processMouseDown);
		// m.onReleased(processMouseUp);
		// m.onHold(processMouseHold);
		// m.onClicked(processMouseClicked);
		// m.onDoubleClicked(processMouseDoubleClicked);

		// // keyboard events
		// var k = App.input.keyboard;
		// k.onDown(k -> if (k == Tab) adjustTabFocus());
		// k.onDown(key -> focusedElement?.keyboardDown(key));
		// k.onUp(key -> focusedElement?.keyboardUp(key));
		// k.onHold(key -> focusedElement?.keyboardHold(key));
		// k.onPressed(char -> focusedElement?.keyboardPressed(char));
	}

	public function setRoot(element:Element) {
		root = element;
	}

	public function elementAt(x:Float, y:Float):Null<Element> {
		var i = root.children.length;
		while (--i >= 0) {
			final c = root.children[i];
			var cat = c.descendantAt(x, y);
			if (cat == null) {
				if (c.covers(x, y))
					return c;
			} else
				return cat;
		};
		return null;
	}

	@:access(s.Window)
	function render(target:RenderTarget) {
		final ctx = target.context2D;

		#if S2D_DEBUG_FPS
		Context3D.reset();
		#end

		root.syncTree();

		ctx.begin();
		ctx.clear(color);
		ctx.pushTransform(projection);
		Element.renderElement(root, target);

		#if (S2D_UI_DEBUG_ELEMENT_BOUNDS == 1)
		var e = elementAt(App.input.mouse.x, App.input.mouse.y);
		if (e != null)
			drawBounds(e, ctx);
		#end

		#if S2D_DEBUG_FPS
		drawDebugInfo(ctx:Context2D);
		#end

		ctx.popTransform();
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
		draw("CPU (ms): " + roundTo(Context3D.cpuTime, 1));
		draw("GPU (ms): " + roundTo(Context3D.gpuTime, 1));
		draw("Draw calls: " + Context3D.drawCalls);
		draw("IB allocations: " + Context3D.ibAllocations);
		draw("VB allocations: " + Context3D.vbAllocations);
	}
	#end

	#if (S2D_UI_DEBUG_ELEMENT_BOUNDS == 1)
	function drawBounds(e:Element, ctx:Context2D) @:privateAccess {
		final style = ctx.style;

		style.opacity = 0.5;
		style.font.family = "font_default";
		style.font.pixelSize = 16;

		final lm = e.left.margin;
		final tm = e.top.margin;
		final rm = e.right.margin;
		final bm = e.bottom.margin;
		final lp = e.left.padding;
		final tp = e.top.padding;
		final rp = e.right.padding;
		final bp = e.bottom.padding;

		style.color = Black;
		ctx.fillRectangle(e.left.position - lm, e.top.position - tm, e.width + lm + rm, e.height + tm + bm);

		// margins
		style.color = s.Color.rgb(0.75, 0.25, 0.75);
		ctx.fillRectangle(e.left.position - lm, e.top.position, lm, e.height);
		ctx.fillRectangle(e.left.position - lm, e.top.position - tm, lm + e.width + rm, tm);
		ctx.fillRectangle(e.left.position + e.width, e.top.position, rm, e.height);
		ctx.fillRectangle(e.left.position - lm, e.top.position + e.height, lm + e.width + rm, bm);

		// padding
		style.color = s.Color.rgb(0.75, 0.75, 0.25);
		ctx.fillRectangle(e.left.position, e.top.position, lp, e.height);
		ctx.fillRectangle(e.left.position + lp, e.top.position, e.width - lp - rp, tp);
		ctx.fillRectangle(e.left.position + e.width - rp, e.top.position, rp, e.height);
		ctx.fillRectangle(e.left.position + lp, e.top.position + e.height - bp, e.width - lp - rp, bp);

		// content
		style.color = s.Color.rgb(0.25, 0.75, 0.75);
		ctx.fillRectangle(e.left.position + lp, e.top.position + tp, e.width - lp - rp, e.height - tp - bp);

		// labels
		style.color = s.Color.rgb(1.0, 1.0, 1.0);
		style.opacity = 1.0;
		final fs = style.font.pixelSize + 5;

		// labels - titles
		if (tm >= fs)
			ctx.drawString("margins", e.left.position - lm + 5, e.top.position - tm + 5);
		if (tp >= fs)
			ctx.drawString("padding", e.left.position + 5, e.top.position + 5);
		if (e.height >= fs)
			ctx.drawString("content", e.left.position + lp + 5, e.top.position + tp + 5);

		// labels - values
		style.font.pixelSize = 14;

		// margins
		var i = 0;
		for (m in [lm, tm, rm, bm]) {
			final str = '${Std.int(m)}px';
			final strWidth = style.font.widthOfCharacters(str.toCharArray(), 0, str.length);
			final strheight = style.font.pixelSize;
			if (m >= strWidth) {
				if (i == 0)
					ctx.drawString(str, e.left.position - (m + strWidth) / 2, e.top.position + e.height / 2);
				else if (i == 2)
					ctx.drawString(str, e.left.position + e.width + (m - strWidth) / 2, e.top.position + e.height / 2);
			}
			if (m >= strheight) {
				if (i == 1)
					ctx.drawString(str, e.left.position + e.width / 2, e.top.position - (m + strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, e.left.position + e.width / 2, e.top.position + e.height + (m - strheight) / 2);
			}
			++i;
		}

		// padding
		var i = 0;
		for (p in [lp, tp, rp, bp]) {
			final str = '${Std.int(p)}px';
			final strWidth = style.font.widthOfCharacters(str.toCharArray(), 0, str.length);
			final strheight = style.font.pixelSize;
			if (p >= strWidth) {
				if (i == 0)
					ctx.drawString(str, e.left.position + (p - strWidth) / 2, e.top.position + e.height / 2);
				else if (i == 2)
					ctx.drawString(str, e.left.position + e.width - (p + strWidth) / 2, e.top.position + e.height / 2);
			}
			if (p >= strheight) {
				if (i == 1)
					ctx.drawString(str, e.left.position + e.width / 2, e.top.position + (p - strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, e.left.position + e.width / 2, e.top.position + e.height - (p + strheight) / 2);
			}
			++i;
		}

		style.font.pixelSize = 22;
		final name = e.toString();
		ctx.drawString(name, App.input.mouse.x - style.font.widthOfCharacters(name.toCharArray(), 0, name.length), App.input.mouse.y - style.font.pixelSize);

		style.font.pixelSize = 16;
		final rect = '${Std.int(e.width)} × ${Std.int(e.height)} at (${Std.int(e.left.position)}, ${Std.int(e.top.position)})';
		ctx.drawString(rect, App.input.mouse.x - style.font.widthOfCharacters(rect.toCharArray(), 0, rect.length), App.input.mouse.y);
	}
	#end

	// function adjustTabFocus() {
	// 	final i = root.children.indexOf(focusedElement);
	// 	for (j in 1...root.children.length) {
	// 		var e = root.children[(i + j) % root.children.length];
	// 		if (e.enabled && (e.focusPolicy & TabFocus != 0)) {
	// 			focusedElement = e;
	// 			return;
	// 		}
	// 	}
	// }
	// function adjustWheelFocus(d:Int) {
	// 	final i = root.children.length + root.children.indexOf(focusedElement);
	// 	for (j in 1...root.children.length) {
	// 		var e = root.children[(i + (d > 0 ? j : -j)) % root.children.length];
	// 		if (e.enabled && (e.focusPolicy & WheelFocus != 0)) {
	// 			focusedElement = e;
	// 			return;
	// 		}
	// 	}
	// }
	// function processMouseMoved(x:Int, y:Int, dx:Int, dy:Int):Void {
	// 	var containsMouse = [];
	// 	processMouseEvent({
	// 		accepted: false,
	// 		x: x,
	// 		y: y,
	// 		dx: dx,
	// 		dy: dy
	// 	}, (c, m) -> {
	// 		containsMouse.push(c);
	// 		if (!entered.contains(c)) {
	// 			entered.push(c);
	// 			c.mouseEntered(x, y);
	// 		}
	// 		c.mouseMoved(m);
	// 	});
	// 	for (c in entered)
	// 		if (!containsMouse.contains(c)) {
	// 			entered.remove(c);
	// 			c.mouseExited(x, y);
	// 		}
	// }
	// function processMouseScrolled(d:Int, x:Int, y:Int):Void {
	// 	processMouseEvent({
	// 		accepted: false,
	// 		delta: d,
	// 		x: x,
	// 		y: y
	// 	}, (c, m) -> c.mouseScrolled(m));
	// }
	// function processMouseDown(b:MouseButton, x:Int, y:Int):Void {
	// 	processMouseEvent({
	// 		accepted: false,
	// 		button: b,
	// 		x: x,
	// 		y: y
	// 	}, (c, m) -> {
	// 		pending.push(c);
	// 		c.mousePressed(m);
	// 	});
	// }
	// function processMouseUp(b:MouseButton, x:Int, y:Int):Void {
	// 	final m = {
	// 		accepted: false,
	// 		button: b,
	// 		x: x,
	// 		y: y
	// 	}
	// 	for (el in pending)
	// 		el.mouseReleased(m);
	// }
	// function processMouseHold(b:MouseButton, x:Int, y:Int):Void {
	// 	processMouseEvent({
	// 		accepted: false,
	// 		button: b,
	// 		x: x,
	// 		y: y
	// 	}, (c, m) -> c.mouseHold(m));
	// }
	// function processMouseClicked(b:MouseButton, x:Int, y:Int):Void {
	// 	var focusedSet = false;
	// 	processMouseEvent({
	// 		accepted: false,
	// 		button: b,
	// 		x: x,
	// 		y: y
	// 	}, (c, m) -> {
	// 		c.mouseClicked(m);
	// 		if (!focusedSet && (c.focusPolicy & ClickFocus != 0)) {
	// 			focusedSet = true;
	// 			focusedElement = c;
	// 		}
	// 	});
	// }
	// function processMouseDoubleClicked(b:MouseButton, x:Int, y:Int):Void {
	// 	processMouseEvent({
	// 		accepted: false,
	// 		button: b,
	// 		x: x,
	// 		y: y
	// 	}, (c, m) -> c.mouseDoubleClicked(m));
	// }
	// function processMouseEvent<T:MouseEvent>(m:T, f:(Element, T) -> Void) {
	// 	var i = entered.length;
	// 	while (--i >= 0) {
	// 		var el = entered[entered.length - i];
	// 		if (el.enabled && el.visible) {
	// 			f(el, m);
	// 			if (m.accepted)
	// 				return;
	// 		}
	// 	}
	// }

	function set_root(element:Element) {
		root = element;
		root.anchors.clear();
		root.width = window.width;
		root.height = window.height;
		return root;
	}

	// function set_focusedElement(value:Element):Element {
	// 	if (focusedElement != value) {
	// 		if (focusedElement != null)
	// 			focusedElement.focused = false;
	// 		value.focused = true;
	// 		focusedElement = value;
	// 	}
	// 	return focusedElement;
	// }
}
