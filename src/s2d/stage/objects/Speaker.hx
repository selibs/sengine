package s2d.stage.objects;

import aura.dsp.panner.Panner;
import se.Audio;
import se.math.SMath;

@:access(se.Audio)
class Speaker extends StageObject {
	var audio:Audio = new Audio();

	@alias public var source:String = audio.asset.source;

	@alias public var balance:Float = audio.balance;
	@alias public var maxDistance:Float = audio.maxDistance;
	@alias public var dopplerStrength:Float = audio.dopplerStrength;
	@alias public var attenuationMode:AttenuationMode = audio.attenuationMode;
	@alias public var attenuationFactor:Float = audio.attenuationFactor;

	public function new(source:String, uncompressed:Bool = true, name:String = "speaker") {
		super(name);
		audio = new Audio(source, uncompressed);
	}

	public inline function play(retrigger:Bool = false) {
		audio.play(retrigger);
	}

	public inline function pause() {
		audio.pause();
	}

	public inline function stop() {
		audio.stop();
	}

	override function syncParentTransform() {
		super.syncParentTransform();
		audio.location = vec3(globalTransform._20, globalTransform._21, z);
	}

	override function syncTransform() {
		super.syncTransform();
		audio.location = vec3(globalTransform._20, globalTransform._21, z);
	}
}
