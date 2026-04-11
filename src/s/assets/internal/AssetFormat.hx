package s.assets.internal;

import haxe.io.Bytes;

abstract class AssetFormat<T> {
	var asset:T;

	public function new(asset:T)
		this.asset = asset;

	abstract public function decode(bytes:Bytes):Void;

	abstract public function encode():Bytes;
}
