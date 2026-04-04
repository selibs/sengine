package s.ui.elements;

abstract class ContainerElement extends Element {
	@:attr var spaceH:Float = 0.0;
	@:attr var spaceV:Float = 0.0;

	@:readonly @:alias public var freeWidth:Float = spaceH;
	@:readonly @:alias public var freeHeight:Float = spaceV;

	override function sync() {
		super.sync();

		if (widthIsDirty || left.paddingIsDirty || right.paddingIsDirty)
			spaceH = width - left.padding - right.padding;

		if (heightIsDirty || top.paddingIsDirty || bottom.paddingIsDirty)
			spaceV = height - top.padding - bottom.padding;
	}
}
