package s.assets.internal.image;

import s.app.Time;

typedef AnimatedFrame = {
	x:Int,
	y:Int,
	u:Float,
	v:Float,
	uw:Float,
	vh:Float,
	duration:Float,
	time:Float
}

class AnimatedImage extends Image {
	final frames:Array<AnimatedFrame> = [];
	var frameWidth:Int = 0;
	var frameHeight:Int = 0;
	var currentTime:Float = 0;
	var atlasColumns:Int = 1;
	var atlasRows:Int = 1;

	@:readonly @:alias public var frameCount:Int = frames.length;
	@:readonly @:alias public var columns:Int = atlasColumns;
	@:readonly @:alias public var rows:Int = atlasRows;

	public var duration(default, null):Float = 0;
	public var currentIndex(default, set):Int = 0;

	@:signal public var currentFrame(default, null):AnimatedFrame;
	
	public var frameRate:Float = 1.0;
	public var loop:Bool = true;
	public var running(default, set):Bool;
	public var paused(default, set):Bool;

	public function play()
		if (!running)
			App.onUpdate(advance);

	public function stop()
		if (running)
			App.offUpdate(advance);

	public function pause()
		if (running && !paused)
			App.offUpdate(advance);

	public function resume()
		if (running && paused)
			App.onUpdate(advance);

	function advance()
		update(Time.delta * frameRate);

	function update(t:Float) {
		if (frameCount <= 0 || t == 0)
			return;

		if (duration <= 0) {
			currentIndex = !loop && t > 0 ? frameCount - 1 : 0;
			if (!loop && t > 0)
				stop();
			return;
		}

		var nextTime = currentTime + t;
		if (loop) {
			nextTime %= duration;
			if (nextTime < 0)
				nextTime += duration;
		} else {
			if (nextTime <= 0) {
				nextTime = 0;
			} else if (nextTime >= duration) {
				currentTime = duration;
				currentIndex = frameCount - 1;
				stop();
				return;
			}
		}

		setPlaybackTime(nextTime);
	}

	override function unload():Void {
		super.unload();

		frames.resize(0);
		frameWidth = 0;
		frameHeight = 0;
		atlasColumns = 1;
		atlasRows = 1;
		duration = 0;
		currentTime = 0;
		currentIndex = 0;
	}

	function set_currentIndex(value:Int) {
		if (frameCount <= 0)
			return currentIndex = 0;

		var index = value % frameCount;
		if (index < 0)
			index += frameCount;
		currentFrame = frames[index];
		currentTime = currentFrame.time;
		return currentIndex = index;
	}

	function setPlaybackTime(value:Float):Void {
		currentTime = value;
		if (frameCount <= 0) {
			currentIndex = 0;
			return;
		}

		if (value >= duration) {
			currentIndex = frameCount - 1;
			return;
		}

		for (i in 0...frameCount) {
			final frame = frames[i];
			if (value < frame.time + frame.duration || i == frameCount - 1) {
				currentFrame = frame;
				@:bypassAccessor currentIndex = i;
				return;
			}
		}
	}

	function set_running(value:Bool):Bool {
		if (value && !running)
			play();
		else if (!value && running)
			stop();
		return value;
	}

	function set_paused(value:Bool):Bool {
		if (value && !paused)
			pause();
		else if (!value && paused)
			resume();
		return value;
	}

	override function get_width():Int
		return frameWidth;

	override function get_height():Int
		return frameHeight;
}
