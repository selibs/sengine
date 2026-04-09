package s;

import kha.System;
import kha.Framebuffer;
import aura.Aura;
import s.Assets;
import s.app.Time;
import s.app.Window;
import s.app.input.Mouse;
import s.app.input.Keyboard;
import s.graphics.shaders.Shader;

/**
 * Application lifecycle states reported by the runtime.
 *
 * These values mirror platform lifecycle callbacks and are exposed through
 * [`App.state`](s.App.state). They are useful when systems need to pause work,
 * mute audio, or skip expensive updates while the application is not active.
 */
enum AppState {
	/** The application was paused, but has not necessarily lost foreground focus. */
	Pause;

	/** The application resumed after a pause. */
	Resume;

	/** The application moved to the background. */
	Background;

	/** The application became the foreground application. */
	Foreground;

	/** The application is shutting down. */
	Shutdown;
}

/**
 * Application entry point and process-level runtime services.
 *
 * `App` owns the runtime bootstrap sequence for the engine. It initializes Kha,
 * input devices, audio, default assets, shader compilation, and the main
 * frame loop.
 *
 * In normal projects `App` is configured declaratively through compile-time
 * `@:app.*` metadata handled by the `@:autoBuild` macro on this class. The
 * macro collects those metadata entries, builds a `kha.SystemOptions` object,
 * and rewrites `main()` into a call to [`start`](s.App.start).
 *
 * Typical usage:
 * ```haxe
 * @:app.title("Game")
 * @:app.window(width = 750, height = 500)
 * @:app.framebuffer(samplesPerPixel = 2, verticalSync = false)
 * class Main extends s.App {
 * }
 * ```
 *
 * The example above becomes roughly:
 * ```haxe
 * s.App.start({
 * 	title: "Game",
 * 	window: {
 * 		width: 750,
 * 		height: 500
 * 	},
 * 	framebuffer: {
 * 		samplesPerPixel: 2,
 * 		verticalSync: false
 * 	}
 * }, window -> {
 * 	// original main body
 * });
 * ```
 *
 * `@:app.*` metadata are therefore just shortcuts for `kha.SystemOptions`.
 * The supported top-level metadata names are:
 *
 * - `@:app.title(value:String)`
 *   Sets `SystemOptions.title`. This is the process title and the default
 *   window title. If `window.title` is omitted, Kha copies this value into it.
 * - `@:app.width(value:Int)`
 *   Sets `SystemOptions.width`. Kha treats this as a shortcut for
 *   `window.width` and overwrites the nested window width when the value is
 *   greater than `0`.
 * - `@:app.height(value:Int)`
 *   Sets `SystemOptions.height`. Kha treats this as a shortcut for
 *   `window.height` and overwrites the nested window height when the value is
 *   greater than `0`.
 * - `@:app.window(...)`
 *   Sets `SystemOptions.window` using named fields from `kha.WindowOptions`.
 * - `@:app.framebuffer(...)`
 *   Sets `SystemOptions.framebuffer` using named fields from
 *   `kha.FramebufferOptions`.
 * - `@:app.audio(...)`
 *   Sets `SystemOptions.audio` using named fields from Kha's internal
 *   audio options object.
 *
 * Supported `@:app.window(...)` fields:
 *
 * - `title:String`
 *   Window title. Overrides `@:app.title(...)` for the actual OS window caption.
 * - `x:Int`
 *   Horizontal window position in screen coordinates. `-1` lets the backend
 *   choose automatically.
 * - `y:Int`
 *   Vertical window position in screen coordinates. `-1` lets the backend
 *   choose automatically.
 * - `width:Int`
 *   Initial client width in pixels.
 * - `height:Int`
 *   Initial client height in pixels.
 * - `display:Int`
 *   Display index for multi-monitor setups. `-1` lets the backend choose.
 * - `visible:Bool`
 *   Whether the window starts visible.
 * - `windowFeatures:kha.WindowFeatures`
 *   Bitmask of optional window capabilities. Combine flags with `|`.
 * - `mode:kha.WindowMode`
 *   Window presentation mode.
 *
 * Available `kha.WindowFeatures` flags for `windowFeatures`:
 *
 * - `kha.WindowFeatures.None`
 *   No optional features.
 * - `kha.WindowFeatures.FeatureResizable`
 *   Allows the user to resize the window.
 * - `kha.WindowFeatures.FeatureMinimizable`
 *   Allows minimizing the window.
 * - `kha.WindowFeatures.FeatureMaximizable`
 *   Allows maximizing the window.
 * - `kha.WindowFeatures.FeatureBorderless`
 *   Requests a borderless window.
 * - `kha.WindowFeatures.FeatureOnTop`
 *   Requests an always-on-top window.
 *
 * The default Kha feature mask is:
 * ```haxe
 * kha.WindowFeatures.FeatureResizable
 * | kha.WindowFeatures.FeatureMaximizable
 * | kha.WindowFeatures.FeatureMinimizable
 * ```
 *
 * Available `kha.WindowMode` values for `mode`:
 *
 * - `kha.WindowMode.Windowed`
 *   Uses a regular OS window.
 * - `kha.WindowMode.Fullscreen`
 *   Uses regular fullscreen mode.
 * - `kha.WindowMode.ExclusiveFullscreen`
 *   Uses exclusive fullscreen mode. In Kha this is primarily meaningful on
 *   Windows and may switch the monitor resolution.
 *
 * Supported `@:app.framebuffer(...)` fields:
 *
 * - `frequency:Int`
 *   Preferred refresh frequency in Hz. The backend may ignore unsupported values.
 * - `verticalSync:Bool`
 *   Enables or disables vertical sync.
 * - `colorBufferBits:Int`
 *   Requested color buffer precision in bits.
 * - `depthBufferBits:Int`
 *   Requested depth buffer precision in bits.
 * - `stencilBufferBits:Int`
 *   Requested stencil buffer precision in bits.
 * - `samplesPerPixel:Int`
 *   Requested MSAA sample count. Use `1` to disable multisampling.
 *
 * Supported `@:app.audio(...)` fields:
 *
 * - `allowMobileWebAudio:Bool`
 *   HTML5-only Kha option that enables `audio2.Audio` initialization on mobile
 *   browsers. Use this when the application must opt into mobile Web Audio
 *   behavior.
 *
 * Example with less common options:
 * ```haxe
 * @:app.title("Game")
 * @:app.window(
 * 	width = 1280,
 * 	height = 720,
 * 	mode = kha.WindowMode.Windowed,
 * 	windowFeatures = kha.WindowFeatures.FeatureResizable
 * 		| kha.WindowFeatures.FeatureMaximizable
 * )
 * @:app.framebuffer(
 * 	verticalSync = true,
 * 	samplesPerPixel = 4,
 * 	depthBufferBits = 24,
 * 	stencilBufferBits = 8
 * )
 * @:app.audio(allowMobileWebAudio = true)
 * class Main extends s.App {}
 * ```
 *
 * In normal projects you usually interact with `App` through:
 * - `@:app.*` metadata to configure startup
 * - [`state`](s.App.state) to react to lifecycle changes
 * - [`input`](s.App.input) to access shared mouse and keyboard devices
 *
 * [`start`](s.App.start) still exists as the low-level runtime entry point, but
 * direct calls are mostly useful for custom bootstraps or tooling code.
 *
 * `App` is process-wide. It should be treated as a singleton-style service
 * layer, not as something instantiated manually.
 *
 * @see kha.SystemOptions
 * @see kha.WindowOptions
 * @see kha.FramebufferOptions
 * @see kha.WindowMode
 * @see kha.WindowFeatures
 */
@:autoBuild(s.macro.AppMacro.build())
class App implements s.shortcut.Shortcut {
	static final logger:Log.Logger = new Log.Logger("APP");
	static final windows:Array<Window> = [];

	@:readonly @:alias public static var language:String = System.language;

	/**
	 * Current application lifecycle state.
	 *
	 * This value changes when the platform reports pause, resume, foreground,
	 * background, or shutdown transitions.
	 *
	 * @default Shutdown
	 */
	@:signal public static var state(default, null):AppState = Shutdown;

	/**
	 * Shared input devices available after startup.
	 *
	 * This field is assigned during application initialization. Access it after
	 * [`start`](s.App.start) has begun setup, not at module load time.
	 */
	public static final input:{mouse:Mouse, keyboard:Keyboard} = {mouse: null, keyboard: null};

	/**
	 * Starts the application.
	 *
	 * This is the low-level bootstrap entry point used by the generated
	 * `@:app.*` startup code. It creates the Kha system, initializes the first
	 * window, loads default engine assets, compiles shaders, and only then
	 * starts the frame loop.
	 *
	 * Most applications should prefer configuring startup declaratively through
	 * class metadata instead of calling this manually.
	 *
	 * The `setup` callback is the place to configure the initial
	 * [`Window`](s.app.Window) and build scenes attached to it when a custom bootstrap
	 * is needed.
	 *
	 * @param options Kha system options used to create the application.
	 * @param setup Called once for the primary window before rendering starts.
	 * @param started Called after initialization finishes and frame delivery has been registered.
	 * @param loadProgress Called with loading progress in the `0.0..1.0` range while boot assets are loading.
	 * @param loadFailed Called when asset loading fails.
	 */
	public static inline function start(options:SystemOptions, ?started:Window->Void, ?loadProgress:Float->Void, ?loadFailed:AssetError->Void) {
		System.start(options, window -> {
			logger.info("Starting");

			input.mouse = new Mouse();
			input.keyboard = new Keyboard();

			System.notifyOnApplicationState(() -> state = Foreground, () -> state = Resume, () -> state = Pause, () -> state = Background,
				() -> state = Shutdown);

			Aura.init();
			Shader.compileShaders();

			Assets.loadShelf({
				fonts: ["font_default" => "font_default"],
				images: ["image_default" => "image_default"]
			}, progress -> {
				if (progress == 1.0) {
					System.notifyOnFrames(render);

					if (started != null)
						started(new Window(window));

					logger.debug("Started");
				}
				if (loadProgress != null)
					loadProgress(progress);
			}, loadFailed);
		});
	}

	/**
	 * Requests application shutdown.
	 *
	 * Whether the request can be honored depends on platform support.
	 */
	public static inline function exit()
		if (!System.stop())
			Log.warning("This application can't be stopped!");

	// aliases

	/**
	 * Registers a file drop handler.
	 *
	 * Use this when your application needs to accept files from the desktop.
	 *
	 * @param dropFiles Called for each dropped file path.
	 */
	public static inline function onDropFiles(dropFiles:String->Void)
		System.notifyOnDropFiles(dropFiles);

	/**
	 * Removes a previously registered file drop handler.
	 *
	 * @param dropFiles Handler to remove.
	 */
	public static inline function offFropFiles(dropFiles:String->Void)
		System.removeDropListener(dropFiles);

	/**
	 * Registers a cut handler.
	 *
	 * @param cut Called when the platform requests cut text.
	 */
	public static inline function onCut(cut:Void->String)
		@:privateAccess onCutCopyPaste(cut, System.copyListener, System.pasteListener);

	/**
	 * Registers a copy handler.
	 *
	 * @param copy Called when the platform requests copy text.
	 */
	public static inline function onCopy(copy:Void->String)
		@:privateAccess onCutCopyPaste(System.cutListener, copy, System.pasteListener);

	/**
	 * Registers a paste handler.
	 *
	 * @param paste Called with pasted text.
	 */
	public static inline function onPaste(paste:String->Void)
		@:privateAccess onCutCopyPaste(System.cutListener, System.copyListener, paste);

	/**
	 * Registers cut, copy, and paste handlers at once.
	 *
	 * This is the low-level clipboard registration point used by the convenience
	 * helpers above.
	 *
	 * @param cut Called when cut text is requested.
	 * @param copy Called when copy text is requested.
	 * @param paste Called with pasted text.
	 */
	public static inline function onCutCopyPaste(cut:Void->String, copy:Void->String, paste:String->Void)
		System.notifyOnCutCopyPaste(cut, copy, paste);

	static function render(frames:Array<Framebuffer>) {
		Time.update(System.time);

		for (frame in frames) {
			final window = windows[@:privateAccess frame.window];
			window.render();
			
			final g2 = frame.g2;
			g2.imageScaleQuality = High;
			g2.mipmapScaleQuality = High;
			g2.begin();
			g2.drawImage(window.backbuffer, 0, 0);
			g2.end();
		}
	}
}
