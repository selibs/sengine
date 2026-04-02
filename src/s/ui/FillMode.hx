package s.ui;

enum FillMode {
	/**
	 * The image is not transformed
	 */
	Pad;

	/**
	 * The image is scaled to fit
	 */
	Stretch;

	/**
	 * The image is scaled uniformly to fill, cropping if necessary
	 */
	Cover;

	/**
	 * The image is scaled uniformly to fit without cropping
	 */
	Contain;

	/**
	 * The image is duplicated horizontally and vertically
	 */
	Tile;

	/**
	 * The image is stretched horizontally and tiled vertically
	 */
	TileVertically;

	/**
	 * The image is stretched vertically and tiled horizontally
	 */
	TileHorizontally;
}
