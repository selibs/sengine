package s.animation;

import s.app.Time;
import s.math.Interpolation;

@:access(s.animation.Action)
abstract class Animation<T> implements s.shortcut.Shortcut {
	var from:T;
	var to:T;

	var time:Float;
	var deltaTime:Float;
	var duration:Float;

	var tick:T->Void;
	var interpolation:Interpolation = Interpolation.Linear;

	var started:Void->Void = () -> {};
	var stopped:Void->Void = () -> {};
	var paused:Void->Void = () -> {};
	var resumed:Void->Void = () -> {};
	var completed:Void->Void = () -> {};

	public var active(default, set):Bool = false;
	public var running(default, set):Bool = false;

	public function new(duration:Float, tick:T->Void) {
		this.duration = duration;
		this.tick = tick;
	}

	public function start(from:T, to:T) {
		if (active)
			return this;

		this.from = from;
		this.to = to;
		this.time = Time.time;
		Time.onTimeChanged(adjust);

		@:bypassAccessor active = true;
		@:bypassAccessor running = true;
		started();
		if (running)
			update(0.0);

		return this;
	}

	public function stop() {
		if (!active)
			return this;
		Time.offTimeChanged(adjust);
		@:bypassAccessor active = false;
		@:bypassAccessor running = false;
		stopped();
		return this;
	}

	public function pause() {
		if (!active || !running)
			return this;
		deltaTime = Time.time - this.time;
		Time.offTimeChanged(adjust);
		@:bypassAccessor running = false;
		paused();
		return this;
	}

	public function resume() {
		if (!active || running)
			return this;
		this.time = Time.time - deltaTime;
		Time.onTimeChanged(adjust);
		@:bypassAccessor running = true;
		resumed();
		return this;
	}

	public function restart() {
		this.time = Time.time;
		if (!running)
			Time.onTimeChanged(adjust);
		@:bypassAccessor active = true;
		@:bypassAccessor running = true;
		started();
		if (running)
			update(0.0);
		return this;
	}

	public function complete() {
		if (!active)
			return this;
		if (running)
			Time.offTimeChanged(adjust);
		@:bypassAccessor active = false;
		@:bypassAccessor running = false;
		update(1.0);
		completed();
		return this;
	}

	public function interp(f:Float->Float) {
		interpolation = f;
		return this;
	}

	public function onStarted(f:Void->Void) {
		started = f;
		return this;
	}

	public function onStopped(f:Void->Void) {
		stopped = f;
		return this;
	}

	public function onPaused(f:Void->Void) {
		paused = f;
		return this;
	}

	public function onResumed(f:Void->Void) {
		resumed = f;
		return this;
	}

	public function onTick(f:T->Void) {
		tick = f;
		return this;
	}

	public function onCompleted(f:Void->Void) {
		completed = f;
		return this;
	}

	function adjust(time:Float) {
		final t = (time - this.time) / duration;
		t < 1.0 ? update(t) : complete();
	}

	function update(t:Float) {
		tick(mix(interpolation(t)));
	}

	abstract function mix(t:Float):T;

	function set_active(value:Bool) {
		if (!active && value)
			start(from, to);
		else if (active && !value)
			stop();
		return value;
	}

	function set_running(value:Bool) {
		if (!running && value)
			resume();
		else if (running && !value)
			pause();
		return value;
	}
}
