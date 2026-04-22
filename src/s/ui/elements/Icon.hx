package s.ui.elements;

import s.assets.Image;

class Icon<T:Image> extends Textured<T> {
	/**
	 * Asset key or path of the image to display.
	 *
	 * Assigning this field forwards the value to the internal
	 * [`ImageAsset`](s.assets.ImageAsset). The exact naming scheme depends on the
	 * project's asset pipeline, but it typically matches the engine's image
	 * identifiers such as `"ui/logo"` or `"atlas/icons"`.
	 */
	@:alias public var source:T = texture;
}
