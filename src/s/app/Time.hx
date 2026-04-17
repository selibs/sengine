package s.app;

/**
 * Global scaled and unscaled time values updated once per frame.
 *
 * `Time` is the engine-wide clock service. It tracks both:
 * - real time, which follows the platform clock
 * - scaled time, which advances by `delta * scale`
 *
 * This separation is useful for pausing or slowing gameplay while still being
 * able to measure real elapsed time for diagnostics or platform-facing tasks.
 */
@:allow(s.App)
class Time implements s.shortcut.Shortcut {
	static var t:Float = 0.0;
	static var timeListeners:Array<{callback:Void->Void, time:Float}> = [];

	@:readonly @:alias public static var time:Float = kha.System.time;
	public static var delta(default, null):Float = 0.0;

	/**
	 * Registers a callback to be called when scaled time reaches a target timestamp.
	 *
	 * The callback is invoked once and then removed automatically.
	 *
	 * @param callback Function to call.
	 * @param time Trigger timestamp in scaled seconds.
	 * @return The created listener record.
	 */
	public static function notifyOnTime(callback:Void->Void, time:Float) {
		var listener = {callback: callback, time: time};
		timeListeners.push(listener);
		return listener;
	}

	public static inline function measure(f:Void->Void):Float {
		final s = time;
		f();
		return time - s;
	}

	static function update() {
		delta = time - t;
		t = time;

		for (l in timeListeners)
			if (time >= l.time) {
				l.callback();
				timeListeners.remove(l);
			}
	}
}
