package s;

import kha.math.FastVector3;
import aura.Aura;
import aura.dsp.panner.Panner;
import aura.dsp.panner.StereoPanner;
import s.math.Vec3;
import s.resource.Sound;
import s.assets.SoundAsset;

class Audio implements s.shortcut.Shortcut {
	var asset:SoundAsset = new SoundAsset();
	var panner:AudioPanner = new AudioPanner();

	@:readonly @:alias var sound:Sound = asset.asset;

	@:alias public var source:String = asset.source;
	@:readonly @:alias public var duration:Float = sound.length;
	@:readonly @:alias public var isLoaded:Bool = asset.isLoaded;

	public var uncompressed(default, set):Bool;

	@:alias public var volume:Float = panner.volume;
	@:alias public var balance:Float = panner.balance;
	@:alias public var location:Vec3 = panner.location;
	@:alias public var maxDistance:Float = panner.maxDistance;
	@:alias public var dopplerStrength:Float = panner.dopplerStrength;
	@:alias public var attenuationMode:AttenuationMode = panner.attenuationMode;
	@:alias public var attenuationFactor:Float = panner.attenuationFactor;

	public function new(?source:String, uncomressed:Bool = true) {
		this.uncompressed = uncompressed;
		this.source = source;
	}

	public inline function play(retrigger:Bool = false, waitForAsset:Bool = true) @:privateAccess {
		asset.delay(_ -> panner.handle?.play(retrigger));
	}

	public inline function pause(waitForAsset:Bool = true) @:privateAccess {
		panner.handle?.pause();
	}

	public inline function stop(waitForAsset:Bool = true) @:privateAccess {
		panner.handle?.stop();
	}

	function set_uncompressed(value:Bool) {
		if (value != uncompressed) {
			uncompressed = value;
			if (uncompressed)
				if (sound != null && sound.uncompressedData == null)
					if (sound.uncompressedData == null)
						sound.uncompress(() -> panner.handle = Aura.createUncompBufferChannel(sound));
					else
						panner.handle = Aura.createUncompBufferChannel(sound);
		}
		return uncompressed;
	}

	@:slot(asset.assetLoaded)
	function __syncAsset__(sound:Sound) {
		if (uncompressed || sound.compressedData == null)
			if (sound.uncompressedData == null)
				sound.uncompress(() -> panner.handle = Aura.createUncompBufferChannel(sound));
			else
				panner.handle = Aura.createUncompBufferChannel(sound);
		else
			panner.handle = Aura.createCompBufferChannel(sound);
	}
}

@:allow(s.Audio.AudioPanner)
private class AudioPanner {
	var panner(default, set):StereoPanner;

	public var handle(default, set):BaseChannelHandle;

	public var volume(default, set):Float = 1.0;
	public var balance(default, set):Float = 0.0;
	public var location(default, set):Vec3 = new Vec3(0, 0, 0);
	public var maxDistance(default, set):Float = 10.0;
	public var dopplerStrength(default, set):Float = 1.0;
	public var attenuationMode(default, set):AttenuationMode = AttenuationMode.Inverse;
	public var attenuationFactor(default, set):Float = 1.0;

	public function new() {}

	private inline function set_handle(value:BaseChannelHandle):BaseChannelHandle {
		handle = value;
		if (handle != null) {
			handle.setVolume(volume);
			if (panner != null)
				panner.setHandle(handle);
			else
				panner = new StereoPanner(handle);
		}
		return handle;
	}

	private inline function set_panner(value:StereoPanner):StereoPanner {
		panner = value;
		if (panner != null) {
			panner.setBalance(balance);
			panner.setLocation((location : FastVector3));
			panner.update3D();
			panner.maxDistance = maxDistance;
			panner.dopplerStrength = dopplerStrength;
			panner.attenuationMode = attenuationMode;
			panner.attenuationFactor = attenuationFactor;
		}
		return panner;
	}

	private inline function set_volume(value:Float):Float {
		volume = value;
		if (handle != null)
			handle.setVolume(value);
		return volume;
	}

	private inline function set_balance(value:Float):Float {
		balance = value;
		if (panner != null)
			panner.setBalance(value);
		return balance;
	}

	private inline function set_location(value:Vec3):Vec3 {
		location = value;
		if (panner != null) {
			panner.setLocation((value : FastVector3));
			panner.update3D();
		}
		return location;
	}

	private inline function set_dopplerStrength(value:Float):Float {
		dopplerStrength = value;
		if (panner != null)
			panner.dopplerStrength = value;
		return balance;
	}

	private inline function set_attenuationMode(value:AttenuationMode):AttenuationMode {
		attenuationMode = value;
		if (panner != null)
			panner.attenuationMode = value;
		return attenuationMode;
	}

	private inline function set_attenuationFactor(value:Float):Float {
		attenuationFactor = value;
		if (panner != null)
			panner.attenuationFactor = value;
		return attenuationFactor;
	}

	private inline function set_maxDistance(value:Float):Float {
		maxDistance = value;
		if (panner != null)
			panner.maxDistance = value;
		return maxDistance;
	}
}
