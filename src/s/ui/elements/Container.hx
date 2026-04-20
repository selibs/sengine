package s.ui.elements;

abstract class Container extends Element {
	@:attr var spaceH:Float = 0.0;
	@:attr var spaceV:Float = 0.0;

	@:readonly @:alias public var freeWidth:Float = spaceH;
	@:readonly @:alias public var freeHeight:Float = spaceV;

	override function update() {
		super.update();

		if (widthDirty || left.paddingDirty || right.paddingDirty)
			spaceH = width - left.padding - right.padding;
		if (heightDirty || top.paddingDirty || bottom.paddingDirty)
			spaceV = height - top.padding - bottom.padding;
	}
}
