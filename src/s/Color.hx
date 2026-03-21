package s;

import s.math.Vec3;
import s.math.Vec4;
import s.math.SMath;
import s.math.SMath.mix as MathMix;

@:forward.new
extern enum abstract Color(Int) from Int to Int {
	final Black = 0xff000000;
	final White = 0xffffffff;
	final Red = 0xffff0000;
	final Blue = 0xff0000ff;
	final Green = 0xff00ff00;
	final Magenta = 0xffff00ff;
	final Yellow = 0xffffff00;
	final Cyan = 0xff00ffff;
	final Purple = 0xff800080;
	final Pink = 0xffffc0cb;
	final Orange = 0xffffa500;
	final Transparent = 0x00000000;

	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;
	public var h(get, set):Float;
	public var s(get, set):Float;
	public var v(get, set):Float;
	public var RGB(get, set):Vec3;
	public var RGBA(get, set):Vec4;
	public var HSV(get, set):Vec3;
	public var HSVA(get, set):Vec4;
	public var HSL(get, set):Vec3;
	public var HSLA(get, set):Vec4;

	public static inline function random():Color {
		return rgba(Math.random(), Math.random(), Math.random());
	}

	overload public static inline function mix(a:Color, b:Color, t:Float):Color {
		return MathMix(a.RGBA, b.RGBA, t);
	}

	overload public static inline function mix(a:Color, b:Color, t:Int):Color {
		return mix(a, b, t / 255);
	}

	overload public static inline function rgb(r:Int, g:Int, b:Int):Color {
		return rgb(r / 255, g / 255, b / 255);
	}

	overload public static inline function rgb(r:Float, g:Float, b:Float):Color {
		return rgba(r, g, b);
	}

	overload public static inline function rgba(r:Int, g:Int, b:Int, a:Int = 255):Color {
		return rgba(r / 255, g / 255, b / 255, a / 255);
	}

	overload public static inline function rgba(r:Int, g:Int, b:Int, a:Float = 1.0):Color {
		return rgba(r / 255, g / 255, b / 255, a);
	}

	overload public static inline function rgba(r:Float, g:Float, b:Float, a:Float = 1.0):Color {
		return (Std.int(a * 255) << 24) | (Std.int(r * 255) << 16) | (Std.int(g * 255) << 8) | Std.int(b * 255);
	}

	overload public static inline function hsv(h:Float, s:Float, v:Float):Color {
		return rgb2hsv(rgb(h, s, v));
	}

	overload public static inline function hsv(h:Int, s:Int, v:Int):Color {
		return hsv(h / 360, s / 100, v / 100);
	}

	overload public static inline function hsva(h:Int, s:Int, v:Int, a:Float = 1.0):Color {
		return hsva(h / 360, s / 100, v / 100, a);
	}

	overload public static inline function hsva(h:Int, s:Int, v:Int, a:Int = 255):Color {
		return hsva(h / 360, s / 100, v / 100, a / 255);
	}

	overload public static inline function hsva(h:Float, s:Float, v:Float, a:Float = 1.0):Color {
		return rgb2hsv(rgba(h, s, v, a));
	}

	overload public static inline function hsl(h:Float, s:Float, l:Float):Color {
		return rgb2hsl(rgb(h, s, l));
	}

	overload public static inline function hsla(h:Int, s:Int, l:Int, a:Int = 255):Color {
		return hsla(h / 360, s / 100, l / 100, a / 255);
	}

	overload public static inline function hsla(h:Int, s:Int, l:Int, a:Float = 1.0):Color {
		return hsla(s / 360, h / 100, l / 100, a);
	}

	overload public static inline function hsla(h:Float, s:Float, l:Float, a:Float = 1.0):Color {
		return rgb2hsl(rgba(h, s, l, a));
	}

	public static inline function hue2rgb(hue:Float):Color {
		var rgb = abs(hue * 6.0 - vec3(3, 2, 4)) * vec3(1, -1, -1) + vec3(-1, 2, 2);
		return clamp(rgb, 0.0, 1.0);
	}

	public static inline function rgb2hcv(color:Color):Color {
		var rgb:Vec3 = color;
		var p = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0 / 3.0) : vec4(rgb.gb, 0.0, -1.0 / 3.0);
		var q = (rgb.r < p.x) ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
		var c = q.x - min(q.w, q.y);
		var h = abs((q.w - q.y) / (6.0 * c + 1e-10) + q.z);
		return vec3(h, c, q.x);
	}

	public static inline function hsv2rgb(color:Color):Color {
		var hsv:Vec3 = color;
		var rgb:Vec3 = hue2rgb(hsv.x);
		return ((rgb - 1.0) * hsv.y + 1.0) * hsv.z;
	}

	public static inline function hsl2rgb(color:Color):Color {
		var hsl:Vec3 = color;
		var rgb:Vec3 = hue2rgb(hsl.x);
		var c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
		return (rgb - 0.5) * c + hsl.z;
	}

	public static inline function rgb2hsv(color:Color):Color {
		var hcv:Vec3 = rgb2hcv(color);
		var s = hcv.y / (hcv.z + 1e-10);
		return vec3(hcv.x, s, hcv.z);
	}

	public static inline function rgb2hsl(rgb:Color):Color {
		var hcv:Vec3 = rgb2hcv(rgb);
		var z = hcv.z - hcv.y * 0.5;
		var s = hcv.y / (1.0 - abs(z * 2.0 - 1.0) + 1e-10);
		return vec3(hcv.x, s, z);
	}

	public static inline function srgb2rgb(srgb:Color):Color {
		return pow(srgb, vec3(2.1632601288));
	}

	public static inline function rgb2srgb(rgb:Color):Color {
		return pow(rgb, vec3(0.46226525728));
	}

	@:from
	public static inline function fromColor(value:kha.Color):Color {
		return value.value;
	}

	@:from
	public static inline function fromString(value:String):Color {
		return switch (value.toLowerCase()) {
			case "black":
				Color.Black;
			case "white":
				Color.White;
			case "red":
				Color.Red;
			case "blue":
				Color.Blue;
			case "green":
				Color.Green;
			case "magenta":
				Color.Magenta;
			case "yellow":
				Color.Yellow;
			case "cyan":
				Color.Cyan;
			case "purple":
				Color.Purple;
			case "pink":
				Color.Pink;
			case "orange":
				Color.Orange;
			case "transparent":
				Color.Transparent;
			default:
				if (!(value.length == 4 || value.length == 7 || value.length == 9) || StringTools.fastCodeAt(value, 0) != "#".code)
					throw 'Invalid Color string: $value';

				if (value.length == 4) {
					final r = value.charAt(1);
					final g = value.charAt(2);
					final b = value.charAt(3);
					value = '#$r$r$g$g$b$b';
				}

				var colorValue = Std.parseInt("0x" + value.substr(1));
				if (value.length == 7)
					colorValue += 0xFF000000;

				return colorValue | 0;
		}
	}

	@:to
	public inline function toColor():kha.Color {
		return this;
	}

	@:to
	public inline function toString():String {
		return '#${StringTools.hex(this, 8)}';
	}

	@:from
	public static inline function fromVec3(value:Vec3):Color {
		return rgb(value.r, value.g, value.b);
	}

	@:from
	public static inline function fromVec4(value:Vec4):Color {
		return rgba(value.r, value.g, value.b, value.a);
	}

	@:to
	public inline function toVec3():Vec3 {
		return vec3(r, g, b);
	}

	@:to
	public inline function toVec4():Vec4 {
		return vec4(r, g, b, a);
	}

	private inline function get_r():Float {
		return ((this & 0x00ff0000) >>> 16) * (1 / 255);
	}

	private inline function set_r(value:Float):Float {
		this = (Std.int(a * 255) << 24) | (Std.int(value * 255) << 16) | (Std.int(g * 255) << 8) | Std.int(b * 255);
		return value;
	}

	private inline function get_g():Float {
		return ((this & 0x0000ff00) >>> 8) * (1 / 255);
	}

	private inline function set_g(value:Float):Float {
		this = (Std.int(a * 255) << 24) | (Std.int(r * 255) << 16) | (Std.int(value * 255) << 8) | Std.int(b * 255);
		return value;
	}

	private inline function get_b():Float {
		return (this & 0x000000ff) * (1 / 255);
	}

	private inline function set_b(value:Float):Float {
		this = (Std.int(a * 255) << 24) | (Std.int(r * 255) << 16) | (Std.int(g * 255) << 8) | Std.int(value * 255);
		return value;
	}

	private inline function get_a():Float {
		return (this >>> 24) * (1 / 255);
	}

	private inline function set_a(value:Float):Float {
		this = (Std.int(value * 255) << 24) | (Std.int(r * 255) << 16) | (Std.int(g * 255) << 8) | Std.int(b * 255);
		return value;
	}

	private inline function get_h():Float {
		return rgb2hsv(this).r;
	}

	private inline function set_h(value:Float):Float {
		var c = hsv2rgb(vec3(value, s, v));
		r = c.r;
		g = c.g;
		b = c.b;
		return value;
	}

	private inline function get_s():Float {
		return rgb2hsv(this).g;
	}

	private inline function set_s(value:Float):Float {
		var c = hsv2rgb(vec3(h, value, v));
		r = c.r;
		g = c.g;
		b = c.b;
		return value;
	}

	private inline function get_v():Float {
		return rgb2hsv(this).b;
	}

	private inline function set_v(value:Float):Float {
		var c = hsv2rgb(vec3(h, s, value));
		r = c.r;
		g = c.g;
		b = c.b;
		return value;
	}

	private inline function get_RGB():Vec3 {
		return toVec3();
	}

	private inline function set_RGB(value:Vec3):Vec3 {
		fromVec3(value);
		return value;
	}

	private inline function get_RGBA():Vec4 {
		return toVec4();
	}

	private inline function set_RGBA(value:Vec4):Vec4 {
		fromVec4(value);
		return value;
	}

	private inline function get_HSV():Vec3 {
		return rgb2hsv(toVec3());
	}

	private inline function set_HSV(value:Vec3):Vec3 {
		fromVec3(hsv2rgb(value));
		return value;
	}

	private inline function get_HSVA():Vec4 {
		return rgb2hsv(toVec3());
	}

	private inline function set_HSVA(value:Vec4):Vec4 {
		fromVec4(hsv2rgb(value));
		return value;
	}

	private inline function get_HSL():Vec3 {
		return rgb2hsv(toVec3());
	}

	private inline function set_HSL(value:Vec3):Vec3 {
		fromVec3(hsl2rgb(value));
		return value;
	}

	private inline function get_HSLA():Vec4 {
		return rgb2hsl(toVec3());
	}

	private inline function set_HSLA(value:Vec4):Vec4 {
		fromVec4(hsl2rgb(value));
		return value;
	}
}
