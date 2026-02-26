package s2d;

import se.App;
import se.Time;
import se.graphics.Context2D;
import se.Window;
import se.Texture;
import se.math.Mat3;

using se.extensions.StringExt;

@:structInit
@:allow(se.App)
@:allow(se.Window)
@:allow(s2d.Element)
class WindowScene extends DrawableElement {
	var window:Window;

	@:signal function set():Void;

	@:signal function unset():Void;

	public var active(get, set):Bool;

	public function new(name:String = "scene", window:Window) {
		super(name);
		this.window = window;
		width = window.width;
		height = window.height;
	}

	public function elementAt(x:Float, y:Float):Null<Element> {
		var i = children.length;
		while (--i >= 0) {
			final c = children[i];
			var cat = c.descendantAt(x, y);
			if (cat == null) {
				if (c.contains(x, y))
					return c;
			} else
				return cat;
		};
		return null;
	}

	override function render(target:Texture) {
		for (e in children)
			e.render(target);
		draw(target);
	}

	function draw(target:Texture) {
		final ctx = target.context2D;
		ctx.transform = Mat3.identity();
		#if (S2D_UI_DEBUG_ELEMENT_BOUNDS == 1)
		var e = elementAt(App.input.mouse.x, App.input.mouse.y);
		if (e != null)
			drawBounds(e, ctx);
		#end
		#if S2D_DEBUG_FPS
		final fps = Std.int(1.0 / Time.delta);
		ctx.style.font = "font_default";
		ctx.style.fontSize = 14;
		ctx.style.color = Black;
		ctx.drawString('FPS: ${fps}', 6, 6);
		ctx.style.color = White;
		ctx.drawString('FPS: ${fps}', 5, 5);
		#end
	}

	function get_active() {
		return window?.scene == this;
	}

	function set_active(value:Bool) {
		if (window != null) {
			if (!active && value)
				window.scene = this;
			else if (active && !value)
				window.scene = null;
		}
		return active;
	}

	#if (S2D_UI_DEBUG_ELEMENT_BOUNDS == 1)
	function drawBounds(e:Element, ctx:Context2D) {
		final style = ctx.style;

		style.opacity = 0.5;
		style.font = "font_default";
		style.fontSize = 16;

		final lm = e.left.margin;
		final tm = e.top.margin;
		final rm = e.right.margin;
		final bm = e.bottom.margin;
		final lp = e.left.padding;
		final tp = e.top.padding;
		final rp = e.right.padding;
		final bp = e.bottom.padding;

		style.color = Black;
		ctx.fillRect(e.absX - lm, e.absY - tm, e.width + lm + rm, e.height + tm + bm);

		// margins
		style.color = se.Color.rgb(0.75, 0.25, 0.75);
		ctx.fillRect(e.absX - lm, e.absY, lm, e.height);
		ctx.fillRect(e.absX - lm, e.absY - tm, lm + e.width + rm, tm);
		ctx.fillRect(e.absX + e.width, e.absY, rm, e.height);
		ctx.fillRect(e.absX - lm, e.absY + e.height, lm + e.width + rm, bm);

		// padding
		style.color = se.Color.rgb(0.75, 0.75, 0.25);
		ctx.fillRect(e.absX, e.absY, lp, e.height);
		ctx.fillRect(e.absX + lp, e.absY, e.width - lp - rp, tp);
		ctx.fillRect(e.absX + e.width - rp, e.absY, rp, e.height);
		ctx.fillRect(e.absX + lp, e.absY + e.height - bp, e.width - lp - rp, bp);

		// content
		style.color = se.Color.rgb(0.25, 0.75, 0.75);
		ctx.fillRect(e.absX + lp, e.absY + tp, e.width - lp - rp, e.height - tp - bp);

		// labels
		style.color = se.Color.rgb(1.0, 1.0, 1.0);
		style.opacity = 1.0;
		final fs = style.fontSize + 5;

		// labels - titles
		if (tm >= fs)
			ctx.drawString("margins", e.absX - lm + 5, e.absY - tm + 5);
		if (tp >= fs)
			ctx.drawString("padding", e.absX + 5, e.absY + 5);
		if (e.height >= fs)
			ctx.drawString("content", e.absX + lp + 5, e.absY + tp + 5);

		// labels - values
		style.fontSize = 14;

		// margins
		var i = 0;
		for (m in [lm, tm, rm, bm]) {
			final str = '${Std.int(m)}px';
			final strWidth = style.font.widthOfCharacters(style.fontSize, str.toCharArray(), 0, str.length);
			final strheight = style.font.height(style.fontSize);
			if (m >= strWidth) {
				if (i == 0)
					ctx.drawString(str, e.absX - (m + strWidth) / 2, e.absY + e.height / 2);
				else if (i == 2)
					ctx.drawString(str, e.absX + e.width + (m - strWidth) / 2, e.absY + e.height / 2);
			}
			if (m >= strheight) {
				if (i == 1)
					ctx.drawString(str, e.absX + e.width / 2, e.absY - (m + strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, e.absX + e.width / 2, e.absY + e.height + (m - strheight) / 2);
			}
			++i;
		}

		// padding
		var i = 0;
		for (p in [lp, tp, rp, bp]) {
			final str = '${Std.int(p)}px';
			final strWidth = style.font.widthOfCharacters(style.fontSize, str.toCharArray(), 0, str.length);
			final strheight = style.font.height(style.fontSize);
			if (p >= strWidth) {
				if (i == 0)
					ctx.drawString(str, e.absX + (p - strWidth) / 2, e.absY + e.height / 2);
				else if (i == 2)
					ctx.drawString(str, e.absX + e.width - (p + strWidth) / 2, e.absY + e.height / 2);
			}
			if (p >= strheight) {
				if (i == 1)
					ctx.drawString(str, e.absX + e.width / 2, e.absY + (p - strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, e.absX + e.width / 2, e.absY + e.height - (p + strheight) / 2);
			}
			++i;
		}

		style.fontSize = 22;
		final name = e.toString();
		ctx.drawString(name, App.input.mouse.x - style.font.widthOfCharacters(style.fontSize, name.toCharArray(), 0, name.length),
			App.input.mouse.y - style.font.height(style.fontSize));

		style.fontSize = 16;
		final rect = '${Std.int(e.width)} × ${Std.int(e.height)} at (${Std.int(e.absX)}, ${Std.int(e.absY)})';
		ctx.drawString(rect, App.input.mouse.x
			- style.font.widthOfCharacters(style.fontSize, rect.toCharArray(), 0, rect.length),
			App.input.mouse.y
			- style.font.height(style.fontSize)
			+ style.fontSize);
	}
	#end
}
