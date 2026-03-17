package s.system.input;

typedef KeyCode = kha.input.KeyCode;

class Keyboard implements s.shortcut.Shortcut {
	var keysTimers:Map<KeyCode, Timer> = [];
	var hotkeyPressedListeners:Map<Array<KeyCode>, Array<Void->Void>> = [];

	public var keysDown:Array<KeyCode> = [];
	public var holdInterval = 0.5;

	@:signal public function down(key:KeyCode);

	@:signal public function up(key:KeyCode);

	@:signal public function hold(key:KeyCode);

	@:signal public function pressed(char:String);

	@:signal public function hotkey(hotkey:Array<KeyCode>);

	@:signal(key) public function keyDown(key:KeyCode);

	@:signal(key) public function keyUp(key:KeyCode);

	@:signal(key) public function keyHold(key:KeyCode);

	@:signal(char) public function charPressed(char:String);

	public function new(id:Int = 0) {
		kha.input.Keyboard.get(id).notify(k -> down(k), k -> up(k), c -> pressed(c));

		onDown(k -> keyDown(k));
		onUp(k -> keyUp(k));
		onHold(k -> keyHold(k));
		onPressed(c -> charPressed(c));
	}

	@:slot(down) function _down(key:KeyCode) {
		keysDown.push(key);
		hotkeyDown(keysDown);

		keysTimers.set(key, Timer.set(() -> {
			if (keysTimers.exists(key))
				hold(key);
		}, holdInterval));
	}

	@:slot(up) function _up(key:KeyCode) {
		keysDown.remove(key);
		hotkeyDown(keysDown);

		keysTimers.get(key)?.stop();
		keysTimers.remove(key);
	}

	function hotkeyDown(hotkey:Array<KeyCode>) {
		if (hotkey.length > 1) {
			this.hotkey(hotkey);
			for (listener in hotkeyPressedListeners.keyValueIterator())
				if (listener.key.length == hotkey.length) {
					var flag = true;
					for (k in listener.key)
						if (!hotkey.contains(k)) {
							flag = false;
							break;
						}
					if (flag) {
						for (callback in listener.value)
							callback();
						break;
					}
				}
		}
	}
}
