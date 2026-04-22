package s.ui.elements;

import s.assets.Image;

/**
 * Image-based drawable markup element.
 *
 * `ImageElement` renders a [`s.assets.Image`](s.assets.Image) inside the
 * rectangular bounds inherited from [`Element`](s.ui.Element). The image is
 * loaded through an internal [`ImageAsset`](s.assets.ImageAsset), can be
 * restricted to a source sub-rectangle with
 * [`sourceClipRect`](s.ui.elements.ImageElement.sourceClipRect), fitted by
 * [`fillMode`](s.ui.elements.ImageElement.fillMode), aligned by
 * [`alignment`](s.ui.elements.ImageElement.alignment), and sampled with
 * configurable texture sampling through
 * [`smooth`](s.ui.elements.ImageElement.smooth),
 * [`mipmap`](s.ui.elements.ImageElement.mipmap), or the higher-level
 * [`sampling`](s.ui.elements.ImageElement.sampling) preset.
 *
 * Fill-mode behavior overview:
 *
 * - [`Pad`](s.ui.FillMode.Pad)
 *   Keeps the source at its natural size relative to the element. This may
 *   leave empty space around the image or cause the image to extend beyond the
 *   element if the source is larger than the destination.
 * - [`Stretch`](s.ui.FillMode.Stretch)
 *   Scales the sampled source rectangle to exactly match the element bounds.
 * - [`Cover`](s.ui.FillMode.Cover)
 *   Scales uniformly to fill the element bounds, cropping the source rectangle
 *   when aspect ratios differ.
 * - [`Contain`](s.ui.FillMode.Contain)
 *   Scales uniformly to fit inside the element bounds without cropping,
 *   potentially leaving empty space.
 * - [`Tile`](s.ui.FillMode.Tile)
 *   Repeats the source horizontally and vertically.
 * - [`TileVertically`](s.ui.FillMode.TileVertically)
 *   Stretches horizontally and repeats vertically.
 * - [`TileHorizontally`](s.ui.FillMode.TileHorizontally)
 *   Repeats horizontally and stretches vertically.
 *
 * Alignment behavior overview:
 *
 * - in `Pad` and `Contain`, alignment places the image inside the remaining
 *   free space
 * - in `Cover`, alignment selects which part of the cropped source remains
 *   visible
 * - in tiled modes, alignment offsets the tile phase when the element size is
 *   not an integer multiple of the tile size
 * - in `Stretch`, alignment has no visible effect because the image always
 *   fills the full destination area
 *
 * The final sampled color is multiplied by the color property and by the
 * element opacity during rendering.
 *
 * Typical usage:
 * ```haxe
 * var image = new ImageElement("ui/logo");
 * image.width = 320;
 * image.height = 180;
 * image.fillMode = Contain;
 * image.alignment = AlignCenter;
 * image.sampling = Trilinear;
 * ```
 *
 * Example using a texture atlas region:
 * ```haxe
 * var icon = new ImageElement("atlas/ui");
 * icon.width = 32;
 * icon.height = 32;
 * icon.sourceClipRect = new Rect(64, 0, 32, 32);
 * icon.fillMode = Stretch;
 * ```
 *
 * Loading is aupdatehronous from the point of view of the element API. Until the
 * asset is available, [`isLoaded`](s.ui.elements.ImageElement.isLoaded) is
 * `false` and the element skips rendering.
 *
 * `ImageElement` otherwise behaves like any other
 * [`Drawable`](s.ui.elements.Drawable): it participates in
 * layout, anchoring, z-ordering, color modulation, visibility, opacity, and
 * child rendering.
 *
 * @see s.assets.Image
 * @see s.assets.ImageAsset
 * @see s.ui.FillMode
 * @see s.ui.Alignment
 * @see s.geometry.Rect
 */
class ImageElement<T:Image> extends Textured<T> {
	/**
	 * Asset key or path of the image to display.
	 *
	 * Assigning this field forwards the value to the internal
	 * [`ImageAsset`](s.assets.ImageAsset). The exact naming scheme depends on the
	 * project's asset pipeline, but it typically matches the engine's image
	 * identifiers such as `"ui/logo"` or `"atlas/icons"`.
	 */
	@:alias public var source:T = texture;

	/**
	 * Creates a new image element bound to the given source asset.
	 *
	 * @param source Asset key or path used to resolve the image asset.
	 */
	public function new(?source:T) {
		super();
		this.source = source;
	}

	function loadSource()
		textureDirty = true;

	function set_source(value:T) {
		source?.offLoaded(loadSource);
		value?.onLoaded(loadSource);
		return texture = value;
	}
}
