package s.system;

import kha.System;
import kha.Framebuffer;
import aura.Aura;
import s.system.Window;
import s.system.input.Mouse;
import s.system.input.Keyboard;
import s.system.resource.Resource;
import s.system.graphics.shaders.Shader;

enum AppState {
	Pause;
	Resume;
	Background;
	Foreground;
	Shutdown;
}

@:autoBuild(s.system.macro.AppMacro.build())
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
	public static inline function onDropFiles(dropFiles:String->Void)
		System.notifyOnDropFiles(dropFiles);

	public static inline function offFropFiles(dropFiles:String->Void)
		System.removeDropListener(dropFiles);

	public static inline function onCut(cut:Void->String)
		@:privateAccess onCutCopyPaste(cut, System.copyListener, System.pasteListener);

	public static inline function onCopy(copy:Void->String)
		@:privateAccess onCutCopyPaste(System.cutListener, copy, System.pasteListener);

	public static inline function onPaste(paste:String->Void)
		@:privateAccess onCutCopyPaste(System.cutListener, System.copyListener, paste);

	public static inline function onCutCopyPaste(cut:Void->String, copy:Void->String, paste:String->Void)
		System.notifyOnCutCopyPaste(cut, copy, paste);

	static function init(window, setup, start, loadProgress, loadFailed) {
		input = {
			mouse: new Mouse(),
			keyboard: new Keyboard()
		}
		s.system.resource.Resource.loadShelf({
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

			w.render(w.backBuffer);

			g2.begin();
			g2.drawImage(w.backBuffer, 0, 0);
			g2.end();
		}
	}
}
