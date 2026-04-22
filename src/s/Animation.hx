package s;

import s.app.Time;
import s.math.Vec2;
import s.math.Vec3;
import s.math.Vec4;

@:nullSafety
class Animation implements s.shortcut.Shortcut {
	@:overload(function(from:Vec2, to:Vec2, duration:Float, advance:Vec2->Void):Animation {})
	@:overload(function(from:Vec3, to:Vec3, duration:Float, advance:Vec3->Void):Animation {})
	@:overload(function(from:Vec4, to:Vec4, duration:Float, advance:Vec4->Void):Animation {})
	public static function mix(from:Float, to:Float, duration:Float = 0.5, advance:Float->Void):Animation
		return new Animation(duration, t -> advance(from * (1.0 - t) + to * t));

	var d:Float = 0.0;
	var l:Int = 0;

	final duration:Float;
	final advance:Float->Void;

	public var loops:Int = 1;
	public var speed:Float = 1.0;
	public var easing:Easing = Easing.Linear;

	public var active(default, set):Bool = false;
	public var paused(default, set):Bool = false;

	@:signal public function started():Void;

	@:signal public function stopped():Void;

	@:signal public function completed():Void;

	public function new(duration:Float = 0.5, advance:Float->Void) {
		this.duration = duration;
		this.advance = advance;
	}

	public function start() {
		if (!active) {
			App.onUpdate(update);
			@:bypassAccessor active = true;
			@:bypassAccessor paused = false;
			started();
			d = 0.0;
			l = 0;
			advance(0.0);
		}
		return this;
	}

	public function stop() {
		if (active) {
			App.offUpdate(update);
			@:bypassAccessor active = false;
			@:bypassAccessor paused = false;
			stopped();
		}
		return this;
	}

	public function complete() {
		if (active) {
			App.offUpdate(update);
			@:bypassAccessor active = false;
			@:bypassAccessor paused = false;
			advance(1.0);
			completed();
		}
		return this;
	}

	public function restart() {
		stop();
		start();
		return this;
	}

	public function pause() {
		if (active && !paused) {
			App.offUpdate(update);
			@:bypassAccessor paused = true;
		}
		return this;
	}

	public function resume() {
		if (active && paused) {
			App.onUpdate(update);
			@:bypassAccessor paused = false;
		}
		return this;
	}

	public function ease(f:Easing) {
		easing = f;
		return this;
	}

	public function loop(loops:Int) {
		this.loops = loops;
		return this;
	}

	function update() {
		d += Time.delta * speed / duration;
		if (d < 1.0)
			advance(easing(d));
		else if (loops == 0 || ++l < loops)
			d = 0.0;
		else
			complete();
	}

	function set_active(value:Bool):Bool {
		if (value && !active)
			start();
		else if (!value && active)
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
}
