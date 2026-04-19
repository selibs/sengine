package s.app.input;

import kha.input.Keyboard as KhaKeyboard;
import s.app.input.Shortcut;

using s.extensions.StringExt;

typedef BlockInterventions = kha.input.Keyboard.BlockInterventions;

class Keyboard implements s.shortcut.Shortcut {
	public static inline function disableSystemInterventions(behavior:BlockInterventions):Void
		KhaKeyboard.disableSystemInterventions(behavior);

	final keysTimers:Map<KeyCode, Timer> = [];
	final shortcutSlots:Array<{shortcut:Shortcut, slot:Void->Void}> = [];
	final modifiers:Array<KeyCode> = [];

	public var holdInterval = 0.5;

	@:signal public function pressed(key:KeyCode);

	@:signal public function released(key:KeyCode);

	@:signal public function hold(key:KeyCode);

	@:signal public function typed(char:Char);

	@:signal public function hotkey(hotkey:Hotkey);

	@:signal(key) public function keyPressed(key:KeyCode);

	@:signal(key) public function keyReleased(key:KeyCode);

	@:signal(key) public function keyHold(key:KeyCode);

	@:signal(char) public function charTyped(char:Char);

	public function new(id:Int = 0) {
		KhaKeyboard.get(id).notify(k -> press((k : Int)), k -> release((k : Int)), c -> type(c));

		App.onStateChanged(s -> if (s == Background) reset());

		onPressed(k -> keyPressed(k));
		onReleased(k -> keyReleased(k));
		onHold(k -> keyHold(k));
		onTyped(c -> charTyped(c));
	}

	public function onShortcut(shortcut:Shortcut, slot:Void->Void)
		if (shortcut != null)
			shortcutSlots.push({shortcut: shortcut, slot: slot});

	public function offShortcut(shortcut:Shortcut, slot:Void->Void)
		if (shortcut != null)
			for (s in shortcutSlots)
				if (s.shortcut == shortcut && s.slot == slot)
					shortcutSlots.remove(s);

	public function press(key:KeyCode) {
		pressed(key);
		keysTimers.set(key, Timer.set(() -> if (keysTimers.exists(key)) hold(key), holdInterval));

		if (key.isModifier) {
			if (!modifiers.contains(key))
				modifiers.push(key);
		} else {
			var h = new Hotkey(key, modifiers.copy());
			hotkey(h);
			for (slot in shortcutSlots)
				if (slot.shortcut.has(h))
					slot.slot();
		}
	}

	public function release(key:KeyCode) {
		released(key);
		modifiers.remove(key);
		keysTimers.get(key)?.stop();
		keysTimers.remove(key);
	}

	public function type(char:Char)
		typed(char);

	public function reset()
		for (key in keysTimers.keys())
			release(key);
}
