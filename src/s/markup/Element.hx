package s.markup;

import s.Texture;
import s.math.SMath;
import s.markup.Style;
import s.markup.Anchors;
import s.markup.geometry.Size;
import s.markup.geometry.Position;

@:allow(s.markup.WindowScene)
class Element extends Object2D<Element> {
	overload extern public static inline function mapToElement(element:Element, x:Float, y:Float):Position {
		return element.mapFromGlobal(x, y);
	}

	overload extern public static inline function mapToElement(element:Element, p:Position):Position {
		return element.mapFromGlobal(p.x, p.y);
	}

	overload extern public static inline function mapFromElement(element:Element, x:Float, y:Float):Position {
		return element.mapToGlobal(x, y);
	}

	overload extern public static inline function mapFromElement(element:Element, p:Position):Position {
		return element.mapToGlobal(p.x, p.y);
	}

	public static function renderElement(element:Element, target:Texture) {
		if (!element.visible)
			return;
		final ctx = target.context2D;
		ctx.pushTransformation(element.transform);
		element.render(target);
		ctx.popTransformation();
	}

	@:attr.group public var anchors(default, never) = new Anchors();
	public var padding(never, set):Float;
	public var margins(never, set):Float;

	@:attr.group public var left(default, never) = new HorizontalAnchor();
	@:attr.group public var hCenter(default, never) = new HorizontalAnchor();
	@:attr.group public var right(default, never) = new HorizontalAnchor();
	@:attr.group public var top(default, never) = new VerticalAnchor();
	@:attr.group public var vCenter(default, never) = new VerticalAnchor();
	@:attr.group public var bottom(default, never) = new VerticalAnchor();

	@:attr public var x(default, set):Float = 0.0;
	@:attr public var y(default, set):Float = 0.0;
	@:attr public var width(default, set):Length = 0.0;
	@:attr public var height(default, set):Length = 0.0;

	public var clip:Bool = false; // TODO: stencil test
	@:attr public var opacity:Float = 1.0;
	@:attr public var visible:Bool = true;
	@:attr.group public var layout(default, never):Layout = new Layout();

	overload extern public inline function setPadding(value:Float):Void {
		setPadding(value, value, value, value);
	}

	overload extern public inline function setPadding(left:Float, top:Float, right:Float, bottom:Float):Void {
		this.left.padding = left;
		this.top.padding = top;
		this.right.padding = right;
		this.bottom.padding = bottom;
	}

	overload extern public inline function setMargins(value:Float):Void {
		setMargins(value, value, value, value);
	}

	overload extern public inline function setMargins(left:Float, top:Float, right:Float, bottom:Float):Void {
		this.left.margin = left;
		this.top.margin = top;
		this.right.margin = right;
		this.bottom.margin = bottom;
	}

	overload extern public inline function setSize(size:Size):Void {
		setSize(size.width, size.height);
	}

	overload extern public inline function setSize(width:Float, height:Float):Void {
		this.width = width;
		this.height = height;
	}

	overload extern public inline function setPosition(position:Position):Void {
		setPosition(position.x, position.y);
	}

	overload extern public inline function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	overload extern public inline function mapFromGlobal(x:Float, y:Float):Position {
		return mapFromGlobal(vec2(x, y));
	}

	overload extern public inline function mapFromGlobal(p:Position):Position {
		return transform * p - vec2(left.position, top.position);
	}

	overload extern public inline function mapToGlobal(x:Float, y:Float):Position {
		return mapToGlobal(vec2(x, y));
	}

	overload extern public inline function mapToGlobal(p:Position):Position {
		return inverse(transform) * p;
	}

	overload extern public inline function covers(x:Float, y:Float):Bool {
		return covers(vec2(x, y));
	}

	overload extern public inline function covers(p:Position):Bool {
		p = mapToGlobal(p);
		return left.position <= p.x && p.x <= right.position && top.position <= p.y && p.y <= bottom.position;
	}

	public function childAt(x:Float, y:Float):Element {
		var i = children.length;
		while (0 < i) {
			final c = children[--i];
			if (c.covers(x, y))
				return c;
		}
		return null;
	}

	public function descendantAt(x:Float, y:Float):Element {
		var i = children.length;
		while (0 < i) {
			final c = children[--i];
			var cat = c.descendantAt(x, y);
			if (cat == null) {
				if (c.covers(x, y))
					return c;
			} else
				return cat;
		};
		return null;
	}

	public function useStylesheet(stylesheet:Stylesheet) {
		for (s in stylesheet)
			useStyle(s);
	}

	public function removeStylesheet(stylesheet:Stylesheet) {
		for (s in stylesheet)
			removeStyle(s);
	}

	public inline function useStyle(style:Style) {
		style.apply(this);
	}

	public inline function removeStyle(style:Style) {
		return style.remove(this);
	}

	override function __childAdded__(child:Element) {
		super.__childAdded__(child);
		if (!child.isHorizontallyAnchored())
			child.left.self.position = left.position + child.x;
		if (!child.isVerticallyAnchored())
			child.top.self.position = top.position + child.y;
	}

	override function __childRemoved__(child:Element) {
		super.__childRemoved__(child);
		if (!child.isHorizontallyAnchored())
			child.left.self.position -= left.position;
		if (!child.isVerticallyAnchored())
			child.top.self.position -= top.position;
	}

	function render(target:Texture) {
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		for (c in children)
			Element.renderElement(c, target);
		ctx.style.popOpacity();
	}

	function syncTree(target:Texture) {
		sync(target);
		for (c in children)
			c.syncTree(target);
		flush();
	}

	function sync(target:Texture) {
		s.markup.macro.ElementMacro.syncAxis("left", "hCenter", "right", "x", "width");
		s.markup.macro.ElementMacro.syncAxis("top", "vCenter", "bottom", "y", "height");
	}

	function set_x(value:Float):Float {
		if (!isHorizontallyAnchored())
			x = value;
		return x;
	}

	function set_y(value:Float):Float {
		if (!isVerticallyAnchored())
			y = value;
		return y;
	}

	function set_width(value:Length):Length {
		if (!isHorizontallyBinded())
			width = value;
		return width;
	}

	function set_height(value:Length):Length {
		if (!isVerticallyBinded())
			height = value;
		return height;
	}

	function set_padding(value:Float) {
		setPadding(value);
		return value;
	}

	function set_margins(value:Float) {
		setMargins(value);
		return value;
	}

	function isHorizontallyAnchored() {
		return anchors.left != null || anchors.hCenter != null || anchors.right != null;
	}

	function isVerticallyAnchored() {
		return anchors.top != null || anchors.vCenter != null || anchors.bottom != null;
	}

	function isHorizontallyBinded() {
		return (anchors.left != null && anchors.hCenter != null || anchors.left != null && anchors.right != null || anchors.hCenter != null
			&& anchors.right != null);
	}

	function isVerticallyBinded() {
		return (anchors.top != null && anchors.vCenter != null || anchors.top != null && anchors.bottom != null || anchors.vCenter != null
			&& anchors.bottom != null);
	}
}
