package s.ui.elements;

class Control<B:Element = Element, C:Element = Element> extends Interactive {
	public final background:B;
	public final content:C;

	@:alias extern public var leftInset:Float = background.left.margin;
	@:alias extern public var topInset:Float = background.top.margin;
	@:alias extern public var rightInset:Float = background.right.margin;
	@:alias extern public var bottomInset:Float = background.bottom.margin;
	@:writeonly @:alias extern public var backgroundInset:Float = background.margins;

	@:alias extern public var leftPadding:Float = content.left.margin;
	@:alias extern public var topPadding:Float = content.top.margin;
	@:alias extern public var rightPadding:Float = content.right.margin;
	@:alias extern public var bottomPadding:Float = content.bottom.margin;
	@:writeonly @:alias extern public var contentPadding:Float = content.margins;

	public inline function setBackgroundInset(value:Float)
		backgroundInset = value;

	public inline function setContentPadding(value:Float)
		contentPadding = value;

	public function new(background:B, content:C) {
		super();
		addChild(this.background = background).anchors.fill(this);
		addChild(this.content = content).anchors.fill(this);
	}
}
