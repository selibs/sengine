package se;

import kha.System;
import kha.Framebuffer;
import aura.Aura;
import se.Window;
import se.system.input.Mouse;
import se.system.input.Keyboard;
import se.animation.Action;
import se.resource.Resource;
import s2d.graphics.Drawers;

@:autoBuild(se.macro.AppMacro.build())
class App {
	static var windows(default, null):Array<Window> = [];

	public static var input(default, null):{mouse:Mouse, keyboard:Keyboard};

	public static function start(options:SystemOptions, ?setup:Window->Void, ?started:Void->Void, ?progress:Float->Void, ?failed:ResourceError->Void) {
		System.start(options, w -> init(w, setup, started, progress, failed));
	}

	public static function exit() {
		if (!System.stop())
			Log.warning("This application can't be stopped!");
	}

	public static function onCutCopyPaste(cut:Void->String, copy:Void->String, paste:String->Void) {
		System.notifyOnCutCopyPaste(cut, copy, paste);
	}

	static function init(window, setup, start, loadProgress, loadFailed) {
		Resource.loadShelf({
			fonts: ["font_default"],
			images: ["image_default"]
		}, _ -> {
			if (start != null)
				start();
			System.notifyOnFrames(frames -> {
				Time.update();
				Action.update(Time.time);
				render(frames);
			});
		}, loadProgress, loadFailed);

		Aura.init();
		Drawers.compile();

		App.input = {
			mouse: new Mouse(),
			keyboard: new Keyboard()
		}

		var w = new Window(window);
		windows.push(w);

		if (setup != null)
			setup(w);
	}

	static function render(frames:Array<Framebuffer>) {
		for (i in 0...frames.length) {
			final g2 = frames[i].g2;
			g2.begin(true);
			g2.drawImage(windows[i].backbuffer, 0, 0);
			g2.end();
		}
	}
}
