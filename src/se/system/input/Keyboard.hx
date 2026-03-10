package se.system.input;

typedef KeyCode = kha.input.KeyCode;

#if !macro
@:build(se.macro.SMacro.build())
#end
class Keyboard {
	var keysTimers:Map<KeyCode, Timer> = [];
	var hotkeyPressedListeners:Map<Array<KeyCode>, Array<Void->Void>> = [];

	public var keysDown:Array<KeyCode> = [];
	public var holdInterval = 0.5;

	@:signal function down(key:KeyCode);

	@:signal function up(key:KeyCode);

	@:signal function hold(key:KeyCode);

	@:signal function pressed(char:String);

	@:signal function hotkey(hotkey:Array<KeyCode>);

	public function new(id:Int = 0) {
		kha.input.Keyboard.get(id).notify(down.emit, up.emit, pressed.emit);
	}

	public function onHotkeyPressed(hotkey:Array<KeyCode>, slot:Void->Void) {
		for (hkl in hotkeyPressedListeners.keys())
			if (hkl == hotkey) {
				hotkeyPressedListeners.get(hkl).push(slot);
				return;
			}
		hotkeyPressedListeners.set(hotkey, [slot]);
	}

	public function offHotkeyPressed(slot:Void->Void) {
		for (key in hotkeyPressedListeners.keys())
			if (hotkeyPressedListeners.get(key).remove(slot))
				return;
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
