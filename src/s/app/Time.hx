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
	/**
	 * Scaled delta time of the last frame in seconds.
	 *
	 * This value already includes [`scale`](s.app.Time.scale).
	 */
	public static var delta:Float = 0.0;

	/**
	 * Multiplier applied to realtime delta when advancing [`time`](s.app.Time.time).
	 *
	 * Set this to `0` to freeze scaled time, or below `1` to slow it down.
	 *
	 * @default 1.0
	 */
	public static var scale:Float = 1.0;

	/**
	 * Real elapsed application time in seconds.
	 *
	 * Unlike [`time`](s.app.Time.time), this value is not affected by [`scale`](s.app.Time.scale).
	 */
	@:signal public static var realTime:Float = 0.0;

	/**
	 * Scaled application time in seconds.
	 *
	 * Timers and time listeners in the engine generally use this clock unless
	 * they explicitly opt into real time.
	 */
	@:signal public static var time:Float = 0.0;

	static var timeListeners:Array<{f:Void->Void, time:Float}> = [];
	static var realTimeListeners:Array<{f:Void->Void, time:Float}> = [];

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
		var listener = {f: callback, time: time};
		timeListeners.push(listener);
		return listener;
	}

	/**
	 * Registers a callback to be called when real time reaches a target timestamp.
	 *
	 * This is useful for timeouts that should keep progressing even if scaled time
	 * is paused or slowed down.
	 *
	 * @param callback Function to call.
	 * @param time Trigger timestamp in real seconds.
	 * @return The created listener record.
	 */
	public static function notifyOnRealTime(callback:Void->Void, time:Float) {
		var listener = {f: callback, time: time};
		realTimeListeners.push(listener);
		return listener;
	}

	/**
	 * Measures how long a function takes in real time.
	 *
	 * This uses [`realTime`](s.app.Time.realTime), so the result is not affected by
	 * [`scale`](s.app.Time.scale).
	 *
	 * @param f Function to execute.
	 * @return Duration in seconds.
	 */
	public static function measure(f:Void->Void):Float {
		var start = Time.realTime;
		f();
		return Time.realTime - start;
	}

	static function update(rt:Float) {
		delta = (rt - realTime) * scale;
		realTime = rt;
		time += delta;
		for (l in timeListeners)
			if (time >= l.time) {
				l.f();
				timeListeners.remove(l);
			}

		for (l in realTimeListeners)
			if (time >= l.time) {
				l.f();
				realTimeListeners.remove(l);
			}
	}
}
