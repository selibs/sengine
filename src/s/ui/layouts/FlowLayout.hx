package s.ui.layouts;

abstract class FlowLayout extends Layout {
	@:attr public var layoutDirection:Direction = LeftToRight;
	@:attr public var uniformCellSizes:Bool = false;

	public function new(?layoutDirection:Direction) {
		super();
		if (layoutDirection != null)
			this.layoutDirection = layoutDirection;
	}
}
