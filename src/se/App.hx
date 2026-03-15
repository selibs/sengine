package se;

import kha.System;
import kha.Framebuffer;
import aura.Aura;
import se.Window;
import se.system.input.Mouse;
import se.system.input.Keyboard;
import se.resource.Resource;
import se.graphics.shaders.Shader;

enum AppState {
	Pause;
	Resume;
	Background;
	Foreground;
	Shutdown;
}

@:autoBuild(se.macro.AppMacro.build())
class App implements s.shortcut.Shortcut {
	static var windows(default, null):Array<Window> = [];

	@:signal public static var state(default, null):AppState = Shutdown;

	public static var input(default, null):{mouse:Mouse, keyboard:Keyboard};

	public static function start(options:SystemOptions, ?setup:Window->Void, ?started:Void->Void, ?progress:Float->Void, ?failed:ResourceError->Void) {
		System.start(options, w -> init(w, setup, started, progress, failed));
	}

	public static function exit() {
		if (!System.stop())
			Log.warning("This application can't be stopped!");
	}

	// aliases
	extern public static inline function onDropFiles(dropFiles:String->Void)
		System.notifyOnDropFiles(dropFiles);

	extern public static inline function offFropFiles(dropFiles:String->Void)
		System.removeDropListener(dropFiles);

	extern public static inline function onCut(cut:Void->String)
		@:privateAccess System.notifyOnCutCopyPaste(cut, System.copyListener, System.pasteListener);

	extern public static inline function onCopy(copy:Void->String)
		@:privateAccess System.notifyOnCutCopyPaste(System.cutListener, copy, System.pasteListener);

	extern public static inline function onPaste(paste:String->Void)
		@:privateAccess System.notifyOnCutCopyPaste(System.cutListener, System.copyListener, paste);

	extern public static inline function onCutCopyPaste(cut:Void->String, copy:Void->String, paste:String->Void)
		System.notifyOnCutCopyPaste(cut, copy, paste);

	static function init(window, setup, start, loadProgress, loadFailed) {
		input = {
			mouse: new Mouse(),
			keyboard: new Keyboard()
		}
		se.resource.Resource.loadShelf({
			fonts: ["font_default"],
			images: ["image_default"]
		}, _ -> if (start != null) start(), loadProgress, loadFailed);

		Aura.init();
		Shader.compileShaders();

		if (setup != null)
			setup(new Window(window));

		System.notifyOnApplicationState(() -> state = Foreground, () -> state = Resume, () -> state = Pause, () -> state = Background, () -> state = Shutdown);
		System.notifyOnFrames(render);
	}

	static function render(frames:Array<Framebuffer>) {
		Time.update(System.time);

		for (i in 0...frames.length) {
			final g2 = frames[i].g2;
			final w = windows[i];
			w.render(w.bA);
			w.swap();
			g2.begin();
			g2.drawImage(w.bB, 0, 0);
			g2.end();
		}
	}
}
