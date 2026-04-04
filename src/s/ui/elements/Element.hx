package s.ui.elements;

import s.math.Vec2;
import s.math.Mat3;
import s.math.SMath;
import s.geometry.Size;
import s.geometry.Position;
import s.graphics.RenderTarget;
import s.ui.Style;
import s.ui.Anchors;

enum ElementPosition {
	Relative;
	Absolute;
}

@:allow(s.ui.WindowScene)
@:allow(s.ui.AttachedAttribute)
class Element extends Object2D<Element> {
	overload extern public static inline function mapToElement(element:Element, x:Float, y:Float):Position
		return element.mapFromGlobal(x, y);

	overload extern public static inline function mapToElement(element:Element, p:Position):Position
		return element.mapFromGlobal(p.x, p.y);

	overload extern public static inline function mapFromElement(element:Element, x:Float, y:Float):Position
		return element.mapToGlobal(x, y);

	overload extern public static inline function mapFromElement(element:Element, p:Position):Position
		return element.mapToGlobal(p.x, p.y);

	overload extern public static inline function mapToElementNormalized(element:Element, x:Float, y:Float):Position
		return element.mapFromGlobalNormalized(x, y);

	overload extern public static inline function mapToElementNormalized(element:Element, p:Position):Position
		return element.mapFromGlobalNormalized(p.x, p.y);

	overload extern public static inline function mapFromElementNormalized(element:Element, x:Float, y:Float):Position
		return element.mapToGlobalNormalized(x, y);

	overload extern public static inline function mapFromElementNormalized(element:Element, p:Position):Position
		return element.mapToGlobalNormalized(p.x, p.y);

	public static function renderElement(element:Element, target:RenderTarget) {
		if (!element.visible)
			return;
		final ctx = target.context2D;
		ctx.pushTransform(element.transform);
		element.render(target);
		ctx.popTransform();
	}

	@:attr var globalTransform:Mat3 = Mat3.identity();

	/**
	 * Optional application-defined tag used for lookup.
	 *
	 * Tags are not required to be unique. Methods such as
	 * [`getChild`](s.ui.elements.Element.getChild), [`getChildren`](s.ui.elements.Element.getChildren), and
	 * [`findChild`](s.ui.elements.Element.findChild) use this field for simple structural
	 * queries.
	 */
	@:attr public var tag:String;

	public var clip:Bool = false; // TODO: stencil test
	@:attr public var opacity:Float = 1.0;
	@:attr public var visible:Bool = true;
	@:attr.attached public final layout:Layout;

	public var padding(never, set):Float;
	public var margins(never, set):Float;
	@:attr.attached public final anchors:Anchors;

	@:attr public var position:ElementPosition = Relative;
	@:attr.attached public final left:HorizontalAnchor;
	@:attr.attached public final hCenter:HorizontalAnchor;
	@:attr.attached public final right:HorizontalAnchor;
	@:attr.attached public final top:VerticalAnchor;
	@:attr.attached public final vCenter:VerticalAnchor;
	@:attr.attached public final bottom:VerticalAnchor;

	@:attr public var x(default, set):Float = 0.0;
	@:attr public var y(default, set):Float = 0.0;
	@:attr public var width(default, set):Float = 0.0;
	@:attr public var height(default, set):Float = 0.0;

	@:attr public var originX:Float = Math.NaN;
	@:attr public var originY:Float = Math.NaN;

	public function new() {
		super();
		layout = new Layout(this);
		anchors = new Anchors(this);
		left = new HorizontalAnchor(this);
		hCenter = new HorizontalAnchor(this);
		right = new HorizontalAnchor(this);
		top = new VerticalAnchor(this);
		vCenter = new VerticalAnchor(this);
		bottom = new VerticalAnchor(this);
	}

	overload extern public inline function setPadding(value:Float):Void
		setPadding(value, value, value, value);

	overload extern public inline function setPadding(left:Float, top:Float, right:Float, bottom:Float):Void {
		this.left.padding = left;
		this.top.padding = top;
		this.right.padding = right;
		this.bottom.padding = bottom;
	}

	overload extern public inline function setMargins(value:Float):Void
		setMargins(value, value, value, value);

	overload extern public inline function setMargins(left:Float, top:Float, right:Float, bottom:Float):Void {
		this.left.margin = left;
		this.top.margin = top;
		this.right.margin = right;
		this.bottom.margin = bottom;
	}

	overload extern public inline function setSize(size:Size):Void
		setSize(size.width, size.height);

	overload extern public inline function setSize(width:Float, height:Float):Void {
		this.width = width;
		this.height = height;
	}

	overload extern public inline function setPosition(position:Position):Void
		setPosition(position.x, position.y);

	overload extern public inline function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	overload extern public inline function setOrigin(origin:Position):Void
		setOrigin(origin.x, origin.y);

	overload extern public inline function setOrigin(x:Float, y:Float):Void {
		originX = x;
		originY = y;
	}

	overload extern public inline function mapFromGlobal(x:Float, y:Float):Position
		return mapFromGlobal(vec2(x, y));

	overload extern public inline function mapFromGlobal(p:Position):Position
		return transform * p - vec2(left.position, top.position);

	overload extern public inline function mapToGlobal(x:Float, y:Float):Position
		return mapToGlobal(vec2(x, y));

	overload extern public inline function mapToGlobal(p:Position):Position
		return inverse(transform) * p;

	overload extern public inline function mapFromGlobalNormalized(x:Float, y:Float):Position
		return mapFromGlobalNormalized(vec2(x, y));

	overload extern public inline function mapFromGlobalNormalized(p:Position):Position
		return mapFromGlobal(p) / vec2(width, height);

	overload extern public inline function mapToGlobalNormalized(x:Float, y:Float):Position
		return mapToGlobalNormalized(vec2(x, y));

	overload extern public inline function mapToGlobalNormalized(p:Position):Position
		return mapToGlobal(p) / vec2(width, height);

	overload extern public inline function covers(x:Float, y:Float):Bool
		return covers(vec2(x, y));

	overload extern public inline function covers(p:Position):Bool {
		p = mapToGlobal(p);
		return left.position <= p.x && p.x <= right.position && top.position <= p.y && p.y <= bottom.position;
	}

	/**
	 * Returns the first direct child with the given tag.
	 *
	 * This only checks direct children and does not recurse into descendants.
	 *
	 * @param tag Tag to match.
	 * @return The found child or `null`.
	 */
	public function getChild(tag:String):Element {
		for (c in children)
			if (c.tag == tag)
				return c;
		return null;
	}

	/**
	 * Returns all direct children with the given tag.
	 *
	 * This only checks direct children and does not recurse into descendants.
	 *
	 * @param tag Tag to match.
	 * @return Matching direct children.
	 */
	public function getChildren(tag:String):Array<Element>
		return children.filter(e -> e.tag == tag);

	/**
	 * Searches the full descendant tree for the first node with the given tag.
	 *
	 * Search order is depth-first in child order.
	 *
	 * @param tag Tag to match.
	 * @return The found descendant or `null`.
	 */
	public function findChild(tag:String):Element {
		for (child in children)
			if (child.tag == tag)
				return child;
			else {
				var c = child.findChild(tag);
				if (c != null)
					return c;
			}
		return null;
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

	public function useStylesheet(stylesheet:Stylesheet)
		for (s in stylesheet)
			useStyle(s);

	public function removeStylesheet(stylesheet:Stylesheet)
		for (s in stylesheet)
			removeStyle(s);

	public inline function useStyle(style:Style)
		style.apply(this);

	public inline function removeStyle(style:Style)
		return style.remove(this);

	override function toString():String
		return super.toString() + (tag != null ? '#$tag' : "");

	override function __childAdded__(child:Element) {
		super.__childAdded__(child);
		if (child.isDirty)
			isDirty = true;
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

	function render(target:RenderTarget) {
		final ctx = target.context2D;
		ctx.style.pushOpacity(opacity);
		for (c in children)
			Element.renderElement(c, target);
		ctx.style.popOpacity();
	}

	function sync() {
		s.ui.macro.ElementMacro.syncAxis("left", "hCenter", "right", "x", "width");
		s.ui.macro.ElementMacro.syncAxis("top", "vCenter", "bottom", "y", "height");

		syncTransform();
	}

	function syncTransform() {
		if (parent != null && parent.globalTransformIsDirty || originXIsDirty || originYIsDirty || transformIsDirty) {
			var ox = left.position + (Math.isNaN(originX) ? width * 0.5 : originX);
			var oy = top.position + (Math.isNaN(originY) ? height * 0.5 : originY);
			globalTransform = Mat3.translation(-ox, -oy) * transform * Mat3.translation(ox, oy);
			if (parent != null)
				globalTransform.copyFrom(parent.globalTransform * globalTransform);
		}
	}

	function syncChild(c:Element)
		c.syncTree();

	function syncTree() {
		if (!isDirty)
			return;
		sync();
		for (c in children)
			syncChild(c);
		flush();
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

	function set_width(value:Float):Float {
		if (!isHorizontallyBinded())
			width = value;
		return width;
	}

	function set_height(value:Float):Float {
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

	function set_isDirty(value:Bool) {
		if (value && parent != null && !parent.isDirty)
			parent.isDirty = true;
		return isDirty = value;
	}
}
