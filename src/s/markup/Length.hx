package s.markup;

enum LengthUnit {
	Pixel;
	Percent;
	ViewportWidth;
	ViewportHeight;
	ViewportMinimum;
	ViewportMaximum;
}

// absolute units
extern inline function px(value:Float):Length
	return new Length(value, Pixel);

extern inline function inch(value:Float):Length
	return new Length(inch2px(value), Pixel);

extern inline function cm(value:Float):Length
	return new Length(cm2px(value), Pixel);

extern inline function mm(value:Float):Length
	return new Length(mm2px(value), Pixel);

extern inline function q(value:Float):Length
	return new Length(q2px(value), Pixel);

extern inline function pc(value:Float):Length
	return new Length(pc2px(value), Pixel);

extern inline function pt(value:Float):Length
	return new Length(pt2px(value), Pixel);

// relative units
extern inline function percent(value:Float):Length
	return new Length(value, Percent);

extern inline function vw(value:Float):Length
	return new Length(value, ViewportWidth);

extern inline function vh(value:Float):Length
	return new Length(value, ViewportHeight);

extern inline function vmin(value:Float):Length
	return new Length(value, ViewportMinimum);

extern inline function vmax(value:Float):Length
	return new Length(value, ViewportMaximum);

@:forward(unit, realIsDirty)
@:forward.new
@:allow(s.markup.Element)
extern abstract Length(LengthData) to LengthData {
	@:from
	public static inline function fromString(value:String):Length {
		final reg = ~/^\s*([+-]?(?:(?:\d+\.?\d*)|(?:\.\d+))(?:[eE][+-]?\d+)?)(.*)$/;
		if (!reg.match(value))
			throw "Invalid length value: " + value;
		var value = Std.parseFloat(reg.matched(1));
		var unit = StringTools.trim(reg.matched(2));
		return switch unit {
			case "px": px(value);
			case "in": inch(value);
			case "mm": mm(value);
			case "cm": cm(value);
			case "Q": q(value);
			case "pc": pc(value);
			case "pt": pt(value);
			case "%": percent(value);
			case "vw": vw(value);
			case "vh": vh(value);
			case "vmin": vmin(value);
			case "vmax": vmax(value);
			default:
				throw "Invalid length unit: " + unit;
		}
	}

	@:from
	public static inline function fromFloat(value:Float):Length {
		return new Length(value, Pixel);
	}

	private var self(get, never):LengthData;

	inline function get_self():LengthData
		return this;

	public var real(get, never):Float;

	inline function get_real():Float
		return this.real;

	@:to
	public inline function toFloat():Float {
		return real;
	}

	@:to
	public inline function toString():String {
		return this.value + switch this.unit {
			case Pixel: "px";
			case Percent: "%";
			case ViewportWidth: "vw";
			case ViewportHeight: "vh";
			case ViewportMinimum: "vmin";
			case ViewportMaximum: "vmax";
		}
	}

	@:op(a *= b)
	static private inline function mulEq(a:Length, b:Float):Length
		return new Length(a.self.value *= b, a.self.unit);

	@:op(a /= b)
	static private inline function divEq(a:Length, b:Float):Length
		return new Length(a.self.value /= b, a.self.unit);

	@:op(a += b)
	static private inline function addEq(a:Length, b:Float):Length
		return new Length(a.self.value += b, a.self.unit);

	@:op(a -= b)
	static private inline function subEq(a:Length, b:Float):Length
		return new Length(a.self.value -= b, a.self.unit);

	@:op(-a)
	static private inline function neg(a:Length):Length
		return new Length(-a.self.value, a.self.unit);

	@:op(++a)
	static private inline function prefixIncrement(a:Length):Length
		return new Length(++a.self.value, a.self.unit);

	@:op(--a)
	static private inline function prefixDecrement(a:Length):Length
		return new Length(--a.self.value, a.self.unit);

	@:op(a++)
	static private inline function postfixIncrement(a:Length):Length
		return new Length(a.self.value++, a.self.unit);

	@:op(a--)
	static private inline function postfixDecrement(a:Length):Length
		return new Length(a.self.value--, a.self.unit);

	@:op(a * b) @:commutative
	static private inline function mul(a:Length, b:Float):Length
		return new Length(a.self.value * b, a.self.unit);

	@:op(a / b)
	static private inline function div(a:Length, b:Float):Length
		return new Length(a.self.value / b, a.self.unit);

	@:op(a / b)
	static private inline function divInv(b:Float, a:Length):Length
		return new Length(b / a.self.value, a.self.unit);

	@:op(a + b) @:commutative
	static private inline function add(a:Length, b:Float):Length
		return new Length(a.self.value + b, a.self.unit);

	@:op(a - b)
	static private inline function sub(a:Length, b:Float):Length
		return new Length(a.self.value - b, a.self.unit);

	@:op(a - b)
	static private inline function subInv(b:Float, a:Length):Length
		return new Length(b - a.self.value, a.self.unit);

	@:op(a == b)
	static private inline function equal(a:Length, b:Length):Bool
		return a.self.real == b.self.real && a.self.value == b.self.value;

	@:op(a != b)
	static private inline function notEqual(a:Length, b:Length):Bool
		return !equal(a, b);
}

extern inline function px2inch(value:Float):Float
	return value / 96;

extern inline function px2mm(value:Float):Float
	return inch2mm(px2inch(value));

extern inline function px2cm(value:Float):Float
	return mm2cm(px2mm(value));

extern inline function px2q(value:Float):Float
	return mm2q(px2mm(value));

extern inline function px2pc(value:Float):Float
	return inch2pc(px2inch(value));

extern inline function px2pt(value:Float):Float
	return inch2pt(px2inch(value));

extern inline function inch2px(value:Float):Float
	return value * 96;

extern inline function inch2mm(value:Float):Float
	return value * 25.4;

extern inline function inch2cm(value:Float):Float
	return value * 2.54;

extern inline function inch2q(value:Float):Float
	return mm2q(inch2mm(value));

extern inline function inch2pc(value:Float):Float
	return value * 6;

extern inline function inch2pt(value:Float):Float
	return value * 72;

extern inline function mm2px(value:Float):Float
	return inch2px(mm2inch(value));

extern inline function mm2inch(value:Float):Float
	return value / 25.4;

extern inline function mm2cm(value:Float):Float
	return value / 10;

extern inline function mm2q(value:Float):Float
	return value * 4;

extern inline function mm2pc(value:Float):Float
	return inch2pc(mm2inch(value));

extern inline function mm2pt(value:Float):Float
	return inch2pt(mm2inch(value));

extern inline function cm2px(value:Float):Float
	return mm2px(cm2mm(value));

extern inline function cm2inch(value:Float):Float
	return value / 2.54;

extern inline function cm2mm(value:Float):Float
	return value * 10;

extern inline function cm2q(value:Float):Float
	return mm2q(cm2mm(value));

extern inline function cm2pc(value:Float):Float
	return inch2pc(cm2inch(value));

extern inline function cm2pt(value:Float):Float
	return inch2pt(cm2inch(value));

extern inline function q2px(value:Float):Float
	return mm2px(q2mm(value));

extern inline function q2inch(value:Float):Float
	return mm2inch(q2mm(value));

extern inline function q2mm(value:Float):Float
	return value / 4;

extern inline function q2cm(value:Float):Float
	return mm2cm(q2mm(value));

extern inline function q2pc(value:Float):Float
	return mm2pc(q2mm(value));

extern inline function q2pt(value:Float):Float
	return mm2pt(q2mm(value));

extern inline function pc2px(value:Float):Float
	return inch2px(pc2inch(value));

extern inline function pc2inch(value:Float):Float
	return value / 6;

extern inline function pc2mm(value:Float):Float
	return inch2mm(pc2inch(value));

extern inline function pc2cm(value:Float):Float
	return inch2cm(pc2inch(value));

extern inline function pc2q(value:Float):Float
	return mm2q(pc2mm(value));

extern inline function pc2pt(value:Float):Float
	return value * 12;

extern inline function pt2px(value:Float):Float
	return inch2px(pt2inch(value));

extern inline function pt2inch(value:Float):Float
	return value / 72;

extern inline function pt2mm(value:Float):Float
	return inch2mm(pt2inch(value));

extern inline function pt2cm(value:Float):Float
	return inch2cm(pt2inch(value));

extern inline function pt2q(value:Float):Float
	return mm2q(pt2mm(value));

extern inline function pt2pc(value:Float):Float
	return value / 12;

@:allow(s.markup.Length)
@:allow(s.markup.Element)
private class LengthData implements s.shortcut.Shortcut {
	@:attr var real:Float = 0.0;

	public var value:Float = 0.0;
	public var unit:LengthUnit = Pixel;

	public function new(value:Float, unit:LengthUnit) {
		this.value = value;
		this.unit = unit;
		switch unit {
			case Pixel:
				this.real = value;
			default:
		}
	}
}
