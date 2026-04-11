package s.ui.elements;

import s.math.Mat3;
import s.math.SMath;
import s.geometry.Size;
import s.geometry.Position;
import s.ui.Style;
import s.ui.AnchorsAttribute;
import s.ui.AnchorLineAttribute;
#if S2D_UI_DEBUG_ELEMENT_BOUNDS
import s.graphics.Context2D;

using s.extensions.StringExt;
#end

@:allow(s.AttachedAttribute)
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

	@:attr var globalTransform:Mat3 = new Mat3();
	@:attr var globalOpacity:Float = 1.0;
	@:attr var globalVisible:Bool = true;
	@:attr(globalOrigin) var globalOriginX:Float = 0.0;
	@:attr(globalOrigin) var globalOriginY:Float = 0.0;

	public var scene(default, null):Scene;

	/**
	 * Optional application-defined tag used for lookup.
	 *
	 * Tags are not required to be unique. Methods such as
	 * [`getChild`](s.ui.elements.Element.getChild), [`getChildren`](s.ui.elements.Element.getChildren), and
	 * [`findChild`](s.ui.elements.Element.findChild) use this field for simple structural
	 * queries.
	 */
	@:attr public var tag:String;

	public var clip:Bool = false; // TODO: stencil test (?)
	@:attr(visibility) @:clamp public var opacity:Float = 1.0;
	@:attr(visibility) public var visible:Bool = true;
	@:attr.attached public final layout:LayoutAttribute;

	public var padding(never, set):Float;
	public var margins(never, set):Float;
	@:attr.attached public final anchors:AnchorsAttribute;

	@:attr.attached public final left:HorizontalAnchor;
	@:attr.attached public final hCenter:HorizontalAnchor;
	@:attr.attached public final right:HorizontalAnchor;
	@:attr.attached public final top:VerticalAnchor;
	@:attr.attached public final vCenter:VerticalAnchor;
	@:attr.attached public final bottom:VerticalAnchor;

	@:attr(horizontal) public var x(default, set):Float = 0.0;
	@:attr(vertical) public var y(default, set):Float = 0.0;
	@:attr(horizontal) public var width(default, set):Float = 0.0;
	@:attr(vertical) public var height(default, set):Float = 0.0;

	@:attr(origin) public var originX:Float = Math.NaN;
	@:attr(origin) public var originY:Float = Math.NaN;

	public function new() {
		super();
		layout = new LayoutAttribute(this);
		anchors = new AnchorsAttribute(this);
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
		return globalTransform * p - vec2(left.position, top.position);

	overload extern public inline function mapToGlobal(x:Float, y:Float):Position
		return mapToGlobal(vec2(x, y));

	overload extern public inline function mapToGlobal(p:Position):Position
		return inverse(globalTransform) * p;

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
		return children.filter(c -> c.tag == tag);

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
		var i = children.count;
		while (0 < i) {
			final c = children[--i];
			if (c.covers(x, y))
				return c;
		}
		return null;
	}

	public function descendantAt(x:Float, y:Float):Element {
		var i = children.count;
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

	function syncTree() {
		sync();
		syncChildren();
		flush();
	}

	function syncChildren()
		for (c in children)
			syncChild(c);

	function syncChild(child:Element)
		if (scene?.root.children.dirty || child.dirty || globalVisibleDirty || globalOpacityDirty || globalTransformDirty)
			child.syncTree();

	override function sync() {
		super.sync();

		// parent
		if (parentDirty)
			scene = parent?.scene;

		// bounds
		s.ui.macro.ElementMacro.syncAxis("left", "hCenter", "right", "x", "width");
		s.ui.macro.ElementMacro.syncAxis("top", "vCenter", "bottom", "y", "height");

		// origin
		if (horizontalDirty || originDirty)
			globalOriginX = left.position + (Math.isNaN(originX) ? width * 0.5 : originX);
		if (verticalDirty || originDirty)
			globalOriginY = top.position + (Math.isNaN(originY) ? height * 0.5 : originY);

		// transform
		if (globalOriginDirty || transformDirty || parentDirty || parent?.globalTransformDirty) {
			globalTransform = Mat3.translation(-globalOriginX, -globalOriginY) * transform * Mat3.translation(globalOriginX, globalOriginY);
			if (parent != null)
				globalTransform *= parent.globalTransform;
		}

		// opacity
		if (visibilityDirty || parentDirty || parent?.globalOpacityDirty) {
			globalOpacity = opacity;
			if (parent != null)
				globalOpacity = parent.globalOpacity * globalOpacity;
		}

		// visible
		if (visibilityDirty || parentDirty || parent?.globalVisibleDirty || globalOpacityDirty || widthDirty || heightDirty) {
			globalVisible = visible && globalOpacity > 0.0 && width > 0.0 && height > 0.0;
			if (parent != null)
				globalVisible = parent.globalVisible && globalVisible;
		}
	}

	#if S2D_UI_DEBUG_ELEMENT_BOUNDS
	function drawBounds(ctx:Context2D) {
		final style = ctx.style;

		style.opacity = 0.5;
		style.font.setDefault();
		style.font.family = "font_default";
		style.font.pixelSize = 16;

		final lm = left.margin;
		final tm = top.margin;
		final rm = right.margin;
		final bm = bottom.margin;
		final lp = left.padding;
		final tp = top.padding;
		final rp = right.padding;
		final bp = bottom.padding;

		style.color = Black;
		ctx.fillRectangle(left.position - lm, top.position - tm, width + lm + rm, height + tm + bm);

		// margins
		style.color = s.Color.rgb(0.75, 0.25, 0.75);
		ctx.fillRectangle(left.position - lm, top.position, lm, height);
		ctx.fillRectangle(left.position - lm, top.position - tm, lm + width + rm, tm);
		ctx.fillRectangle(left.position + width, top.position, rm, height);
		ctx.fillRectangle(left.position - lm, top.position + height, lm + width + rm, bm);

		// padding
		style.color = s.Color.rgb(0.75, 0.75, 0.25);
		ctx.fillRectangle(left.position, top.position, lp, height);
		ctx.fillRectangle(left.position + lp, top.position, width - lp - rp, tp);
		ctx.fillRectangle(left.position + width - rp, top.position, rp, height);
		ctx.fillRectangle(left.position + lp, top.position + height - bp, width - lp - rp, bp);

		// content
		style.color = s.Color.rgb(0.25, 0.75, 0.75);
		ctx.fillRectangle(left.position + lp, top.position + tp, width - lp - rp, height - tp - bp);

		// labels
		style.color = s.Color.rgb(1.0, 1.0, 1.0);
		style.opacity = 1.0;
		final fs = style.font.pixelSize + 5;

		// labels - titles
		if (tm >= fs)
			ctx.drawString("margins", left.position - lm + 5, top.position - tm + 5);
		if (tp >= fs)
			ctx.drawString("padding", left.position + 5, top.position + 5);
		if (height >= fs)
			ctx.drawString("content", left.position + lp + 5, top.position + tp + 5);

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
					ctx.drawString(str, left.position - (m + strWidth) / 2, top.position + height / 2);
				else if (i == 2)
					ctx.drawString(str, left.position + width + (m - strWidth) / 2, top.position + height / 2);
			}
			if (m >= strheight) {
				if (i == 1)
					ctx.drawString(str, left.position + width / 2, top.position - (m + strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, left.position + width / 2, top.position + height + (m - strheight) / 2);
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
					ctx.drawString(str, left.position + (p - strWidth) / 2, top.position + height / 2);
				else if (i == 2)
					ctx.drawString(str, left.position + width - (p + strWidth) / 2, top.position + height / 2);
			}
			if (p >= strheight) {
				if (i == 1)
					ctx.drawString(str, left.position + width / 2, top.position + (p - strheight) / 2);
				else if (i == 3)
					ctx.drawString(str, left.position + width / 2, top.position + height - (p + strheight) / 2);
			}
			++i;
		}

		style.font.pixelSize = 22;
		final name = toString();
		ctx.drawString(name, App.input.mouse.x - style.font.widthOfCharacters(name.toCharArray(), 0, name.length), App.input.mouse.y - style.font.pixelSize);

		style.font.pixelSize = 16;
		final rect = '${Std.int(width)} × ${Std.int(height)} at (${Std.int(left.position)}, ${Std.int(top.position)})';
		ctx.drawString(rect, App.input.mouse.x - style.font.widthOfCharacters(rect.toCharArray(), 0, rect.length), App.input.mouse.y);
	}
	#end

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
		if (!isHorizontallyLocked())
			width = value;
		return width;
	}

	function set_height(value:Float):Float {
		if (!isVerticallyLocked())
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

	inline function isHorizontallyAnchored()
		return anchors.left != null || anchors.hCenter != null || anchors.right != null;

	inline function isVerticallyAnchored()
		return anchors.top != null || anchors.vCenter != null || anchors.bottom != null;

	inline function isHorizontallyLocked()
		return (anchors.left != null && anchors.hCenter != null || anchors.left != null && anchors.right != null || anchors.hCenter != null
			&& anchors.right != null);

	inline function isVerticallyLocked()
		return (anchors.top != null && anchors.vCenter != null || anchors.top != null && anchors.bottom != null || anchors.vCenter != null
			&& anchors.bottom != null);
}
