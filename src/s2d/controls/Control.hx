package s2d.controls;

import s2d.Element;

class Control<B:Element, C:Element> extends Element {
	public var background(default, set):B;
	public var content(default, set):C;

	@:alias public var topInset:Float = background.top.margin;
	@:alias public var leftInset:Float = background.left.margin;
	@:alias public var bottomInset:Float = background.bottom.margin;
	@:alias public var rightInset:Float = background.right.margin;
	@:writeonly @:alias public var inset:Float = background.anchors.margins;

	@:alias public var topOffset:Float = content.top.margin;
	@:alias public var leftOffset:Float = content.left.margin;
	@:alias public var bottomOffset:Float = content.bottom.margin;
	@:alias public var rightOffset:Float = content.right.margin;
	@:writeonly @:alias public var offset:Float = content.anchors.margins;

	public function new() {
		super();
		enabled = true;
	}

	function set_background(value:B):B {
		if (background != null) {
			removeChild(background);
			background.anchors.unfill();
		}
		if (value != null) {
			addChild(value);
			value.anchors.fill(this);
		}
		background = value;
		return background;
	}

	function set_content(value:C):C {
		if (content != null) {
			removeChild(content);
			content.anchors.unfill();
		}
		if (value != null) {
			addChild(value);
			value.anchors.fill(this);
		}
		content = value;
		return content;
	}
}
