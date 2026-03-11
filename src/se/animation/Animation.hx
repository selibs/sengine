package se.animation;

import se.Time;
import se.math.SMath;
import se.animation.Action.Actuator;

#if !macro
@:build(s.shortcut.Macro.build())
#end
@:access(se.animation.Action)
abstract class Animation<T> {
	var actuator:Actuator;

	var _onStart:Void->Void = () -> {};
	var _onStop:Void->Void = () -> {};
	var _onPause:Void->Void = () -> {};
	var _onResume:Void->Void = () -> {};
	var _tick:T->Void;

	var _started:Bool = false;
	var _paused:Bool = false;
	var dTime:Float = 0.0;

	public var from:T;
	public var to:T;
	public var started(get, set):Bool;
	public var paused(get, set):Bool;

	@:alias public var duration:Float = actuator.duration;
	@:alias public var easing:Float->Float = actuator.easing;

	public function new(from:T, to:T, duration:Float, onTick:T->Void) {
		this.from = from;
		this.to = to;

		_tick = onTick;
		actuator = new Actuator(duration, tick);
	}

	public function start() {
		if (!started) {
			actuator.start = Time.time;
			Action.actuators.push(actuator);
		}
		_started = true;
		_onStart();
		return this;
	}

	public function stop() {
		if (started)
			actuator.stop();
		_started = false;
		_onStop();
		return this;
	}

	public function pause() {
		if (started && !paused) {
			actuator.stop();
			dTime = Time.time - actuator.start;
		}
		paused = true;
		_onPause();
		return this;
	}

	public function resume() {
		if (started && paused) {
			actuator.start = Time.time - dTime;
			Action.actuators.push(actuator);
		}
		paused = false;
		_onResume();
		return this;
	}

	public function restart() {
		stop();
		start();
		return this;
	}

	public function complete() {
		if (started)
			actuator.complete();
		started = false;
		return this;
	}

	public function ease(f:Float->Float) {
		actuator.ease(f);
		return this;
	}

	public function onStarted(f:Void->Void) {
		_onStart = f;
		return this;
	}

	public function onStopped(f:Void->Void) {
		_onStop = f;
		return this;
	}

	public function onPaused(f:Void->Void) {
		_onPause = f;
		return this;
	}

	public function onResumed(f:Void->Void) {
		_onResume = f;
		return this;
	}

	public function onTick(f:T->Void) {
		_tick = f;
		return this;
	}

	public function onCompleted(f:Void->Void) {
		actuator.onCompleted(f);
		return this;
	}

	function tick(t:Float) {
		_tick(update(t));
	}

	abstract function update(t:Float):T;

	function get_started() {
		return _started;
	}

	function set_started(value:Bool) {
		if (!started && value)
			start();
		else if (started && !value)
			stop();
		return value;
	}

	function get_paused() {
		return _paused;
	}

	function set_paused(value:Bool) {
		if (!paused && value)
			pause();
		else if (paused && !value)
			resume();
		return value;
	}
}
