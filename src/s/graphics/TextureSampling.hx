package s.graphics;

/**
 * Sampling presets
 *
 * These presets combine nearest/linear sampling with optional mipmapping.
 */
enum TextureSampling {
	/** Nearest-neighbor sampling without mipmaps. */
	Nearest;

	/** Linear sampling without mipmaps. */
	Bilinear;

	/** Nearest-neighbor sampling with mipmaps enabled. */
	Prefiltered;

	/** Linear sampling with linear mip blending. */
	Trilinear;
}
