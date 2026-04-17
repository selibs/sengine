const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const { Server } = require("./server.js");

const args = new Map();
for (let i = 2; i < process.argv.length; i += 1) {
	const arg = process.argv[i];
	if (arg.startsWith("--")) {
		const next = process.argv[i + 1];
		if (next != null && !next.startsWith("--")) {
			args.set(arg, next);
			i += 1;
		} else {
			args.set(arg, "true");
		}
	}
}

const workspace = path.resolve(args.get("--workspace") || process.cwd());
const khaDir = args.get("--kha");
const target = args.get("--target") || "debug-html5";
const compileServerPort = Number(args.get("--haxe-server-port") || "6111");

if (!khaDir) {
	throw new Error("--kha is required");
}

const makeScript = path.join(khaDir, "make");
const buildRoot = path.join(workspace, "build");
const buildDir = path.join(workspace, "build", target);
const buildAssetsDir = path.join(buildDir, "assets");
const hxmlName = `project-${target}.hxml`;
const hxmlPath = path.join(buildRoot, hxmlName);
const server = new Server(buildDir, "kha.js");

let child = null;
let haxeServer = null;
let haxeServerReady = false;
let haxeServerStarting = null;
let compiling = false;
let pendingMode = null;
let lastChanged = null;
let output = "";
let debounceTimer = null;

const ignoredDirs = new Set([".git", "build", "node_modules", ".idea"]);
const ignoredSuffixes = [".tmp", ".temp", ".log"];
const codeExtensions = new Set([".hx"]);
const fullBuildExtensions = new Set([".glsl", ".json", ".xml", ".png", ".jpg", ".jpeg", ".bmp", ".tga", ".tif", ".tiff", ".psd", ".hdr", ".exr", ".ttf", ".frag", ".vert"]);
const BUILD_FULL = "full";
const BUILD_HAXE = "haxe";

function stripAnsi(value) {
	return value.replace(/\x1B\[[0-9;]*[A-Za-z]/g, "");
}

function normalizeOutput(value) {
	return stripAnsi(value).replace(/\r/g, "").trim();
}

function normalizePath(value) {
	return value.replace(/\\/g, "/");
}

function getAssetTopLevelEntry(relativePath) {
	const normalized = normalizePath(relativePath);
	if (!normalized.startsWith("assets/")) {
		return null;
	}

	const rest = normalized.slice("assets/".length);
	if (rest.length === 0) {
		return null;
	}

	const slash = rest.indexOf("/");
	return slash === -1 ? rest : rest.slice(0, slash);
}

function isProjectAssetPath(relativePath) {
	const entry = getAssetTopLevelEntry(relativePath);
	if (entry == null) {
		return false;
	}

	if (!fs.existsSync(hxmlPath) || !fs.existsSync(buildAssetsDir)) {
		return true;
	}

	return fs.existsSync(path.join(buildAssetsDir, entry));
}

function collectError(outputText) {
	const lines = normalizeOutput(outputText)
		.split("\n")
		.map((line) => line.trimEnd())
		.filter(Boolean);
	if (lines.length === 0) {
		return "Haxe compile error.";
	}

	const noise = [
		/^Haxe compilation\.\.\.$/,
		/^Haxe compile end\.$/,
		/^Haxe compile error\.$/,
		/^Done\.$/,
		/^Creating Kha project\.$/,
		/^Exporting asset \d+ of \d+/,
		/^Compiling shader \d+ of \d+/,
	];
	const isNoise = (line) => noise.some((pattern) => pattern.test(line));
	const isHaxeError = (line) =>
		/\.(hx|hxml|json|xml|glsl):\d+:/i.test(line) ||
		/^Error:/i.test(line) ||
		/\b(Type not found|Unknown identifier|Unexpected|Missing ;|Build failed|Invalid)\b/.test(line);

	const errorLines = lines.filter((line) => !isNoise(line) && isHaxeError(line));
	if (errorLines.length > 0) {
		return errorLines.join("\n");
	}

	const filtered = lines.filter((line) => !isNoise(line));
	if (filtered.length > 0) {
		return filtered.slice(-8).join("\n");
	}

	return "Haxe compile error.";
}

function isIgnored(relativePath) {
	if (!relativePath || relativePath.startsWith("..")) {
		return true;
	}
	const normalized = normalizePath(relativePath);
	if (normalized.startsWith("assets/") && !isProjectAssetPath(normalized)) {
		return true;
	}
	const parts = relativePath.split(path.sep);
	if (parts.some((part) => ignoredDirs.has(part))) {
		return true;
	}
	return ignoredSuffixes.some((suffix) => relativePath.endsWith(suffix));
}

function mergeMode(left, right) {
	if (left === BUILD_FULL || right === BUILD_FULL) {
		return BUILD_FULL;
	}
	return left || right;
}

function isCodeFile(relativePath) {
	const normalized = relativePath.replace(/\\/g, "/");
	const ext = path.extname(normalized).toLowerCase();
	if (!codeExtensions.has(ext)) {
		return false;
	}
	return (
		normalized.startsWith("src/") ||
		normalized.startsWith("sengine/src/") ||
		/^sengine\/libs\/[^/]+\/src\//.test(normalized)
	);
}

function needsFullBuild(filePath) {
	if (!filePath || !fs.existsSync(hxmlPath)) {
		return true;
	}

	const relative = path.relative(workspace, filePath);
	const ext = path.extname(relative).toLowerCase();
	const normalized = normalizePath(relative);

	if (isCodeFile(relative)) {
		return false;
	}

	if (normalized === "khafile.js" || normalized === "sengine/khafile.js") {
		return true;
	}
	if (normalized.startsWith("assets/")) {
		return isProjectAssetPath(normalized);
	}
	if (normalized.startsWith("shaders/")) {
		return true;
	}
	if (normalized.includes("/assets/") || normalized.includes("/shaders/")) {
		return true;
	}
	if (fullBuildExtensions.has(ext)) {
		return true;
	}
	return false;
}

function getBuildMode(filePath) {
	if (!filePath) {
		return BUILD_FULL;
	}
	const relative = path.relative(workspace, filePath);
	if (isCodeFile(relative)) {
		return BUILD_HAXE;
	}
	if (needsFullBuild(filePath)) {
		return BUILD_FULL;
	}
	return null;
}

function scheduleBuild(filePath, forcedMode = null) {
	const mode = forcedMode || getBuildMode(filePath);
	if (!mode) {
		return;
	}
	lastChanged = filePath || lastChanged;
	if (compiling) {
		pendingMode = mergeMode(pendingMode, mode);
		return;
	}
	if (debounceTimer) {
		clearTimeout(debounceTimer);
	}
	debounceTimer = setTimeout(() => {
		debounceTimer = null;
		void build(mode);
	}, 75);
}

function reportError(message) {
	server.reportError(message);
}

function maybeReloadAsset() {
	if (!lastChanged) {
		return;
	}
	const relative = path.relative(workspace, lastChanged);
	if (relative.startsWith("src") || relative.startsWith(`sengine${path.sep}src`)) {
		return;
	}
	const builtPath = path.join(buildDir, relative);
	if (fs.existsSync(builtPath) && fs.statSync(builtPath).isFile()) {
		server.reloadAsset(relative.replace(/\\/g, "/"));
	}
}

function spawnBuild(command, parameters, cwd) {
	return new Promise((resolve) => {
		child = spawn(command, parameters, {
			cwd,
			stdio: ["ignore", "pipe", "pipe"],
		});

		const onData = (chunk) => {
			const text = chunk.toString();
			output += text;
			process.stdout.write(text);
		};
		const onErrorData = (chunk) => {
			const text = chunk.toString();
			output += text;
			process.stderr.write(text);
		};

		child.stdout.on("data", onData);
		child.stderr.on("data", onErrorData);
		child.on("close", (code) => {
			child = null;
			resolve(code);
		});
	});
}

function startHaxeServer() {
	if (haxeServerReady) {
		return Promise.resolve();
	}
	if (haxeServerStarting) {
		return haxeServerStarting;
	}

	haxeServerStarting = new Promise((resolve, reject) => {
		let settled = false;
		haxeServer = spawn("haxe", ["--wait", String(compileServerPort)], {
			cwd: buildRoot,
			stdio: ["ignore", "pipe", "pipe"],
		});

		const fail = (error) => {
			if (settled) {
				return;
			}
			settled = true;
			haxeServerReady = false;
			haxeServerStarting = null;
			reject(error);
		};

		haxeServer.on("error", fail);
		haxeServer.stdout.on("data", (chunk) => {
			process.stdout.write(chunk.toString());
		});
		haxeServer.stderr.on("data", (chunk) => {
			process.stderr.write(chunk.toString());
		});
		haxeServer.on("exit", (code, signal) => {
			const error = new Error(`Haxe compilation server exited (${code ?? "null"}${signal ? `, ${signal}` : ""})`);
			haxeServer = null;
			haxeServerReady = false;
			haxeServerStarting = null;
			if (!settled) {
				fail(error);
			}
		});

		setTimeout(() => {
			if (settled) {
				return;
			}
			if (haxeServer && haxeServer.exitCode == null && !haxeServer.killed) {
				settled = true;
				haxeServerReady = true;
				haxeServerStarting = null;
				resolve();
				return;
			}
			fail(new Error("Failed to start Haxe compilation server."));
		}, 200);
	});

	return haxeServerStarting;
}

function build(mode) {
	compiling = true;
	pendingMode = null;
	output = "";
	console.log("Haxe compilation...");
	const changed = lastChanged ? path.relative(workspace, lastChanged).replace(/\\/g, "/") : "<initial>";
	console.log(`hotload build mode: ${mode} (${changed})`);

	return new Promise((resolve) => {
		const runBuild = mode === BUILD_FULL
			? Promise.resolve(spawnBuild(process.execPath, [makeScript, target, "--hotload"], workspace))
			: startHaxeServer().then(() => spawnBuild("haxe", ["--connect", String(compileServerPort), hxmlName], buildRoot));

		runBuild.then((code) => {
			child = null;
			compiling = false;
			if (code === 0) {
				console.log("Haxe compile end.");
				try {
					server.reload();
					if (mode === BUILD_FULL) {
						maybeReloadAsset();
					}
				} catch (error) {
					reportError(String(error && error.stack ? error.stack : error));
				}
			} else {
				console.log("Haxe compile error.");
				reportError(collectError(output));
			}

			if (pendingMode) {
				const nextMode = pendingMode;
				pendingMode = null;
				scheduleBuild(lastChanged, nextMode);
			}
			resolve();
		}).catch((error) => {
			child = null;
			compiling = false;
			console.log("Haxe compile error.");
			reportError(String(error && error.stack ? error.stack : error));
			if (pendingMode) {
				const nextMode = pendingMode;
				pendingMode = null;
				scheduleBuild(lastChanged, nextMode);
			}
			resolve();
		});
	});
}

function watchDir(root) {
	if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) {
		return;
	}
	fs.watch(root, { recursive: true }, (_eventType, filename) => {
		if (!filename) {
			return;
		}
		const fullPath = path.join(root, filename.toString());
		const relative = path.relative(workspace, fullPath);
		if (isIgnored(relative)) {
			return;
		}
		scheduleBuild(fullPath);
	});
}

function close() {
	if (child) {
		child.kill();
	}
	if (haxeServer) {
		haxeServer.kill();
	}
	server.close();
}

process.on("SIGINT", () => {
	close();
	process.exit(0);
});

process.on("SIGTERM", () => {
	close();
	process.exit(0);
});

process.on("exit", close);

watchDir(workspace);
scheduleBuild(null, BUILD_FULL);
