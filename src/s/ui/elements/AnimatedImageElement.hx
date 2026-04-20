package s.ui.elements;

import s.assets.internal.image.AnimatedImage;

class AnimatedImageElement extends ImageElement<AnimatedImage> {
	var frameClipX:Float = 0.0;
	var frameClipY:Float = 0.0;
	var frameClipZ:Float = 1.0;
	var frameClipW:Float = 1.0;

	@:readonly @:alias extern public var duration:Float = source.duration;
	@:readonly @:alias extern public var frameCount:Int = source.frameCount;
	@:readonly @:attr @:alias extern public var currentFrame:AnimatedFrame = source.currentFrame;

	@:alias extern public var frameRate:Float = source.frameRate;
	@:alias extern public var currentIndex:Int = source.currentIndex;

	public function new(?source:AnimatedImage, play:Bool = true) {
		super(source);
		if (play)
			this.play();
	}

	public function play()
		source.play();

	public function stop()
		source.stop();

	public function pause()
		source.pause();

	public function resume()
		source.resume();

	@:slot(source.currentFrameChanged)
	function markCurrentFrame(_)
		currentFrameDirty = true;

	override function update() {
		super.update();

		if (!isLoaded || frameCount <= 0)
			return;

		if (clipRectDirty) {
			frameClipX = clipRect.x;
			frameClipY = clipRect.y;
			frameClipZ = clipRect.z;
			frameClipW = clipRect.w;
		}

		if (clipRectDirty || currentFrameDirty) {
			clipRect.x = currentFrame.u + frameClipX * currentFrame.uw;
			clipRect.y = currentFrame.v + frameClipY * currentFrame.vh;
			clipRect.z = frameClipZ * currentFrame.uw;
			clipRect.w = frameClipW * currentFrame.vh;
			currentFrameDirty = false;
		}
	}
}
