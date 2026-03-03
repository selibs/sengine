package se;

import kha.System;
import kha.Framebuffer;
import aura.Aura;
import se.system.Window;
import se.system.input.Mouse;
import se.system.input.Keyboard;
import se.animation.Action;
import se.resource.Resource;
import s2d.graphics.Drawers;

@:build(se.macro.SMacro.build())
class App {
	static var undoListener:Void->Void;
	static var redoListener:Void->Void;

	@:signal static function update();

	public static var input(default, null):{
		var mouse:Mouse;
		var keyboard:Keyboard;
	};
	public static var windows(default, null):Array<Window>;

	public static function start(options:SystemOptions, ?setup:Window->Void, ?started:Void->Void, ?progress:Float->Void, ?failed:ResourceError->Void) {
		onUpdate(() -> {
			Time.update();
			Action.update(Time.time);
		});

		System.start(options, window -> {
			Resource.loadShelf({
				fonts: ["font_default"],
				images: ["image_default"]
			}, _ -> {
				if (started != null)
					started();
				System.notifyOnFrames(frames -> {
					update();
					render(frames);
				});
			}, progress, failed);

			Aura.init();
			Drawers.compile();

			App.input = {
				mouse: new Mouse(),
				keyboard: new Keyboard()
			}

			input.keyboard.onHotkey(hotkey -> switch hotkey {
				case [Control, Z] if (undoListener != null):
					undoListener();
				case [Control, Shift, Z] if (undoListener != null):
					undoListener();
				default:
			});

			var w = new Window(window);
			windows = [w];
			if (setup != null)
				setup(w);
		});
	}

	public static function exit() {
		if (!System.stop())
			Log.warning("This application can't be stopped!");
	}

	public static function onUndo(listener:Void->Void) {
		undoListener = listener;
	}

	public static function onRedo(listener:Void->Void) {
		redoListener = listener;
	}

	public static function onCutCopyPaste(cut:Void->String, copy:Void->String, paste:String->Void) {
		System.notifyOnCutCopyPaste(cut, copy, paste);
	}

	static inline function render(frames:Array<Framebuffer>) @:privateAccess {
		for (i in 0...frames.length)
			windows[i].render(frames[i]);
	}
}
