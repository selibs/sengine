package s;

import s.Time;

@:access(s.Time)
class Timer {
	var listener:{
		f:Void->Void,
		time:Float
	};

	var callback:Void->Void;
	var originalCallback:Void->Void;
	var delay:Float;

	public var started(get, set):Bool;

	/**
		Creates a timer and immediately starts it
		@param callback A function to call after the timer was triggered
		@param delay Amount of seconds to wait
		@return Returns the timer instance
	 */
	public static function set(callback:Void->Void, delay:Float):Timer {
		final timer = new Timer(callback, delay);
		timer.start();
		return timer;
	}

	/**
		Creates a timer
		@param callback A function to call after the timer was triggered
		@param delay Amount of seconds to wait
	 */
	public function new(callback:Void->Void, delay:Float) {
		this.originalCallback = callback;
		this.callback = callback;
		this.delay = delay;
	}

	/**
		Starts the timer
		@param lock Whether to skip if the timer is already started
		@return Returns true if the timer was started
	 */
	public function start(lock:Bool = true):Bool {
		if (!lock || !started) {
			callback = originalCallback;
			listener = Time.notifyOnTime(callback, Time.time + delay);
			return true;
		}
		return false;
	}

	/**
		Stops the timer
	 */
	public function stop() {
		Time.timeListeners.remove(listener);
		callback = originalCallback;
	}

	/**
		Starts the timer repeatedly.
		@param count How many times to start the timer. 0 for infinity
		@param lock Whether to skip if the timer is already started
		@return Returns true if the timer was repeated
	 */
	public function repeat(count:Int = 1, lock:Bool = true):Bool {
		if (count < 0)
			return false;
		if (!lock || !started) {
			final f = originalCallback;
			if (count > 0)
				callback = function() {
					f();
					count--;
					if (count > 0)
						listener = Time.notifyOnTime(callback, Time.time + delay);
					else
						callback = f;
				};
			else
				callback = function() {
					f();
					listener = Time.notifyOnTime(callback, Time.time + delay);
				};
			listener = Time.notifyOnTime(callback, Time.time + delay);
			return true;
		}
		return false;
	}

	/**
		Loops the timer.
		@param lock Whether to skip if the timer is already started
		@return Returns true if the timer was looped
	 */
	public function loop(lock:Bool = true):Bool {
		return repeat(0, lock);
	}

	function get_started():Bool {
		return Time.timeListeners.contains(listener);
	}

	function set_started(value:Bool):Bool {
		if (!started && value)
			start();
		else if (started && !value)
			stop();
		return started;
	}
}
