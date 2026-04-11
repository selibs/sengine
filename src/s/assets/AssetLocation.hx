package s.assets;

import haxe.io.Bytes;
import haxe.io.Path;
import s.URI;
import s.assets.AssetLocation;

using StringTools;

enum AssetLocationType {
	Resource(name:String);
	File(path:String);
	Web(url:URI);
}

abstract AssetLocation(AssetLocationType) from AssetLocationType to AssetLocationType {
	static function extractResourceName(uri:URI):String {
		var resource = uri.host != null ? uri.host.host : "";
		if (uri.path != null && uri.path != "") {
			var path = uri.path.startsWith("/") ? uri.path.substr(1) : uri.path;
			resource = resource != "" ? '$resource/$path' : path;
		}
		return resource;
	}

	static function extractName(path:String):String {
		if (path == null || path == "")
			return "";

		var normalized = path.replace("\\", "/");
		if (normalized.length > 1 && normalized.endsWith("/"))
			normalized = normalized.substring(0, normalized.length - 1);

		var slash = normalized.lastIndexOf("/");
		return slash >= 0 ? normalized.substr(slash + 1) : normalized;
	}

	static function classifyBareLocation(value:String):AssetLocation {
		var normalized = value.replace("\\", "/");

		if (isLikelyWebLocation(normalized))
			return Web(defaultWebUri(normalized));

		if (isLikelyFilePath(normalized))
			return File(normalized);

		return Resource(value);
	}

	static function isLikelyFilePath(value:String):Bool {
		if (value.startsWith("/") || value.startsWith("./") || value.startsWith("../"))
			return true;

		return value.indexOf("/") >= 0 || value.indexOf("\\") >= 0;
	}

	static function isWindowsFilePath(value:String):Bool
		return ~/^[A-Za-z]:(?:[\/\\]|$)/.match(value) || ~/^[A-Za-z]:(?:\/\/|\\\\)/.match(value);

	static function isWindowsDriveScheme(uri:URI, source:String):Bool
		return uri != null && uri.proto != null && uri.proto.length == 1 && ~/^[A-Za-z]:(?:[\/\\]|\/\/|\\\\)/.match(source);

	static function isLikelyWebLocation(value:String):Bool {
		var slash = value.indexOf("/");
		var host = slash >= 0 ? value.substring(0, slash) : value;

		if (!isLikelyDomain(host))
			return false;

		// Treat bare domains and domain-prefixed paths as web locations.
		return true;
	}

	static function isLikelyDomain(value:String):Bool {
		if (value == null || value == "")
			return false;
		if (value.startsWith(".") || value.endsWith(".") || value.indexOf(".") < 0)
			return false;
		if (!~/^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/.match(value))
			return false;

		var labels = value.split(".");
		var tld = labels[labels.length - 1];
		return ~/^[A-Za-z]{2,63}$/.match(tld);
	}

	static function defaultWebUri(value:String):URI
		return new URI("https", true, true, HostInfo.fromString(value.split("/")[0]), null, null,
			value.indexOf("/") >= 0 ? value.substr(value.indexOf("/")) : "", null, null);

	static function normalizeFilePath(value:String):String
		return value.replace("\\", "/");

	static function cloneUri(uri:URI):URI
		return new URI(uri.proto, uri.secure, uri.hasAuthority, uri.host, uri.user, uri.pass, uri.path, uri.query, uri.fragment);

	@:from
	public static function fromString(value:String):AssetLocation {
		if (value == null)
			return null;

		value = value.trim();
		if (value == "")
			return Resource(value);

		if (isWindowsFilePath(value))
			return File(normalizeFilePath(value));

		var uri:URI = value;
		if (uri == null || uri.proto == null)
			return classifyBareLocation(value);

		return switch uri.proto {
			case "resource": Resource(extractResourceName(uri));
			case "file": File(uri.path ?? "");
			case "http", "https", "ws", "wss": Web(cloneUri(uri));
			case _:
				if (isWindowsDriveScheme(uri, value)) File(normalizeFilePath(value)); else Web(cloneUri(uri));
		}
	}

	public var uri(get, never):URI;
	public var extension(get, never):String;
	public var target(get, never):String;

	@:to
	public function toString():String
		return uri;

	@:to
	function get_uri():URI
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

	function get_extension():String
		return switch this {
			case Resource(name): Path.extension(name ?? "");
			case File(path): Path.extension(path ?? "");
			case Web(url): Path.extension(url.path ?? "");
		}

	function get_target():String
		return switch this {
			case Resource(name): name;
			case File(path): path;
			case Web(url): url.toString();
		}
}
