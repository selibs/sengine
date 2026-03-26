package s.assets;

import haxe.io.Path;
import s.URI;

using StringTools;

enum AssetLocationType {
	Resource(name:String);
	File(path:String);
	Web(url:URI);
}

extern enum abstract AssetLocation(AssetLocationType) from AssetLocationType to AssetLocationType {
	@:from
	public static inline function fromString(value:String):AssetLocation {
		if (value == null)
			return null;

		var uri:URI = value;
		if (uri == null || uri.proto == null)
			return Resource(value);

		return switch uri.proto {
			case "resource": Resource(extractResourceName(uri));
			case "file": File(uri.path ?? "");
			case _: Web(cloneUri(uri));
		}
	}

	public var uri(get, never):URI;
	public var extension(get, never):String;
	public var target(get, never):String;

	@:to
	public inline function toString():String
		return uri.toString();

	@:to
	inline function get_uri():URI
		return switch this {
			case Resource(name):
				'resource://$name';
			case File(path):
				var normalized = path.replace("\\", "/");
				var prefix = normalized.startsWith("/") ? "file://" : "file:///";
				'$prefix$normalized';
			case Web(url):
				cloneUri(url);
		}

	inline function get_extension():String
		return switch this {
			case Resource(name): Path.extension(name ?? "");
			case File(path): Path.extension(path ?? "");
			case Web(url): Path.extension(url.path ?? "");
		}

	inline function get_target():String
		return switch this {
			case Resource(name): name;
			case File(path): path;
			case Web(url): url.toString();
		}
}

private function extractResourceName(uri:URI):String {
	var resource = uri.host != null ? uri.host.host : "";
	if (uri.path != null && uri.path != "") {
		var path = uri.path.startsWith("/") ? uri.path.substr(1) : uri.path;
		resource = resource != "" ? '$resource/$path' : path;
	}
	return resource;
}

private function extractName(path:String):String {
	if (path == null || path == "")
		return "";

	var normalized = path.replace("\\", "/");
	if (normalized.length > 1 && normalized.endsWith("/"))
		normalized = normalized.substring(0, normalized.length - 1);

	var slash = normalized.lastIndexOf("/");
	return slash >= 0 ? normalized.substr(slash + 1) : normalized;
}

private function cloneUri(uri:URI):URI
	return new URI(uri.proto, uri.isSecure, uri.hasAuthority, uri.host, uri.user, uri.pass, uri.path, uri.query, uri.fragment);
