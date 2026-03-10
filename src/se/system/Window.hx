package se.system;

import kha.WindowMode;
import kha.WindowOptions;
import kha.Window as KhaWindow;

#if !macro
@:build(se.macro.SMacro.build())
#end
@:allow(se.App)
class Window {
	var backbuffer:Texture;
	var window:KhaWindow;

	@alias public var x:Int = window.x;
	@alias public var y:Int = window.y;
	public var width(default, null):Int = 0;
	public var height(default, null):Int = 0;

	@alias public var title:String = window.title;
	@alias public var mode:WindowMode = window.mode;
	@readonly @alias public var vSynced:Bool = window.vSynced;

	@:inject(syncFeatures) public var onTop:Bool = false;
	@:inject(syncFeatures) public var resizable:Bool = true;
	@:inject(syncFeatures) public var borderless:Bool = false;
	@:inject(syncFeatures) public var minimizable:Bool = true;
	@:inject(syncFeatures) public var maximizable:Bool = true;

	@:inject(syncFramebuffer) public var frequency:Int = 60;
	@:inject(syncFramebuffer) public var verticalSync:Bool = true;
	@:inject(syncFramebuffer) public var colorBufferBits:Int = 32;
	@:inject(syncFramebuffer) public var depthBufferBits:Int = 16;
	@:inject(syncFramebuffer) public var stencilBufferBits:Int = 8;
	@:inject(syncFramebuffer) public var samplesPerPixel:Int = 1;

	@:signal function resized(width:Int, height:Int);

	@:access(se.App)
	public function new(w:KhaWindow) {
		window = w;
		width = w.width;
		height = w.height;
		backbuffer = new Texture(w.width, w.height);
		App.windows.push(this);

		window.notifyOnResize((w, h) -> {
			width = w;
			height = h;
			backbuffer.unload();
			backbuffer = new Texture(width, height);
			resized(w, h);
		});
	}

	public inline function move(x:Int, y:Int) {
		window.move(x, y);
	}

	public inline function resize(width:Int, height:Int) {
		window.resize(width, height);
	}

	public inline function destroy() {
		KhaWindow.destroy(window);
	}

	function syncFramebuffer() {
		window.changeFramebuffer({
			frequency: frequency,
			verticalSync: verticalSync,
			colorBufferBits: colorBufferBits,
			depthBufferBits: depthBufferBits,
			stencilBufferBits: stencilBufferBits,
			samplesPerPixel: samplesPerPixel
		});
	}

	function syncFeatures() {
		var top = onTop ? FeatureOnTop : None;
		var res = resizable ? FeatureResizable : None;
		var bor = borderless ? FeatureBorderless : None;
		var min = minimizable ? FeatureMinimizable : None;
		var max = maximizable ? FeatureMaximizable : None;
		window.changeWindowFeatures(res | min | max | bor | top);
	}
}
