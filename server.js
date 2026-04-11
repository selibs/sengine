const fs = require("fs");
const path = require("path");
const { WebSocketServer } = require("ws");

const JsType = {
	CLASSIC: "Classic",
	ES5: "Es5",
};

const ParseMode = {
	REGULAR: "ParseRegular",
	METHODS: "ParseMethods",
};

const BodySection = {
	CODE: "Code",
	SINGLE_COMMENT: "SingleComment",
	MULTI_COMMENT: "MultiComment",
	SINGLE_QUOTES: "SingleQuotes",
	DOUBLE_QUOTES: "DoubleQuotes",
	BACKTICKS: "Backticks",
};

class Server {
	static logResult = false;

	constructor(buildDir, scriptName, port = 3220) {
		this.buildDir = buildDir;
		this.scriptName = scriptName;
		this.port = port;
		this.file = null;
		this.clients = new Set();
		this.server = new WebSocketServer({ port: this.port });
		this.server.on("connection", (socket) => this.handleSocket(socket));
		this.server.on("error", (error) => this.reportError(`Server error: ${formatError(error)}`));
	}

	close() {
		for (const socket of this.clients) {
			socket.close();
		}
		this.clients.clear();
		this.server?.close();
	}

	handleSocket(socket) {
		this.clients.add(socket);
		socket.on("close", () => this.clients.delete(socket));
		socket.on("error", (error) => {
			this.clients.delete(socket);
			this.reportError(`Client error: ${formatError(error)}`);
		});
	}

	sendTo(socket, messages) {
		if (!socket || socket.readyState !== 1) {
			return;
		}
		socket.send(JSON.stringify(messages));
	}

	broadcast(messages) {
		for (const socket of this.clients) {
			this.sendTo(socket, messages);
		}
	}

	reload() {
		const target = path.join(this.buildDir, this.scriptName);
		try {
			const data = fs.readFileSync(target, "utf8");
			if (this.file == null) {
				this.file = new Parser(data);
				return;
			}
			const next = new Parser(data);
			const diff = this.file.makeDiffTo(next);
			if (Server.logResult && diff.length > 0) {
				console.log(JSON.stringify(diff));
			}
			if (diff.length > 0) {
				this.broadcast(diff.map((patch) => ({ type: "patch", patch })));
			}
			this.file = next;
		} catch (error) {
			this.reportError(`Reload failed: ${formatError(error)}`);
		}
	}

	reloadAsset(assetPath) {
		try {
			const filePath = path.join(this.buildDir, assetPath);
			const data = fs.readFileSync(filePath).toString("base64");
			this.broadcast([{
				type: "patch",
				patch: {
					type: "reloadAsset",
					path: assetPath,
					data,
				},
			}]);
		} catch (error) {
			this.reportError(`Asset reload failed for ${assetPath}: ${formatError(error)}`);
		}
	}

	reportError(message) {
		console.error(`HOTLOAD reportError: ${message} (clients: ${this.clients.size})`);
		if (this.clients.size > 0) {
			this.broadcast([{ type: "error", error: message }]);
		}
	}
}

class Parser {
	static logTypes = false;
	static logBodies = false;
	static logSkips = false;

	constructor(file) {
		this.classes = new Map();
		this.enums = new Map();
		this.matchClosure = /\(function \(.*"use strict";/;
		this.matchExportsObj = /var \$hx_exports =/;
		this.matchConstructor = /^var ([^ ]+) =.* function\((.*)\) \{( };)?$/;
		this.matchClassicConstructor = /^var ([^ ]+) = \$hxClasses\["([^ ]+)"\] =.* function\((.*)\) \{( };)?$/;
		this.matchObj = /var ([^ ]+) =.*\{ ?}/;
		this.matchClassicObj = /^var ([^ ]+) = \$hxClasses\["([^ ]+)"\] =.*\{ ?};$/;
		this.matchClassNameId = /\$hxClasses\["(.+)"\] = (.+);/;
		this.matchParent = /__super__ = (.+);/;
		this.matchInterfaces = /__interfaces__ = (.+);/;
		this.matchStaticVar = /^([^[ .]+)\.([^ .]+) = (.+);/;
		this.matchStaticArr = /^([^ ]+)\.([^ ]+) = \(function\(\$this\)/;
		this.matchStaticFunc = /^([^ ]+)\.([^ ]+) = function\((.*)\)/;
		this.matchFunc = /([^ ,\t]+): function\((.*)\)/;
		this.matchEnum = /^var ([^ []+) = \$hxEnums\["([^"]+)/;
		this.matchEnumConstructs = /^([^ ]+)\.__constructs__ = (.+);$/;
		this.mode = ParseMode.REGULAR;
		this.currentClass = null;
		this.lines = file.split("\n");
		this.num = 0;
		this.jsType = JsType.CLASSIC;
		this.jsTypeDetected = false;

		while (this.num < this.lines.length) {
			const line = this.lines[this.num];
			this.mode === ParseMode.REGULAR ? this.parseRegular(line) : this.parseMethods(line);
			this.num += 1;
		}
	}

	getJsType() {
		return this.jsType + (this.jsTypeDetected ? "" : " (Undetected)");
	}

	traceType(message) {
		if (Parser.logTypes) {
			console.log(message);
		}
	}

	traceBody(message) {
		if (Parser.logBodies) {
			console.log(message);
		}
	}

	traceSkip(message) {
		if (Parser.logSkips) {
			console.log(message);
		}
	}

	parseRegular(line) {
		let match;

		if (!this.jsTypeDetected && this.matchClosure.test(line)) {
			this.jsTypeDetected = true;
			this.jsType = JsType.ES5;
			return;
		}
		if (!this.jsTypeDetected && this.matchExportsObj.test(line)) {
			this.jsTypeDetected = true;
			this.jsType = JsType.CLASSIC;
			return;
		}
		if (this.jsType === JsType.ES5 && (match = line.match(this.matchConstructor))) {
			this.setConstructor(match[1], this.parseArgs(match[2]));
			return;
		}
		if (this.jsType === JsType.CLASSIC && (match = line.match(this.matchClassicConstructor))) {
			this.setConstructor(match[1], this.parseArgs(match[3]));
			this.setNameId(match[1], match[2]);
			return;
		}
		if ((match = line.match(this.matchParent))) {
			if (this.currentClass == null) {
				this.traceSkip(`Skip parent ${match[1]} without current class`);
				return;
			}
			const parent = match[1];
			const parentClass = this.classes.get(parent);
			if (!parentClass) {
				this.traceSkip(`Skip ${this.currentClass.name} parent ${parent}`);
				return;
			}
			this.currentClass.parent = parentClass.nameId;
			return;
		}
		if ((match = line.match(this.matchInterfaces))) {
			if (this.currentClass == null) {
				this.traceSkip(`Skip interfaces ${match[1]} without current class`);
				return;
			}
			this.currentClass.interfaces = match[1];
			return;
		}
		if (line.endsWith(".prototype = {") || line.includes(".prototype = $extend(")) {
			this.currentClass = this.findPrototypeClass(line);
			if (this.currentClass == null) {
				this.traceSkip(`Skip prototype without known class: ${line}`);
				return;
			}
			this.traceType(`${this.currentClass.name} {`);
			this.mode = ParseMode.METHODS;
			return;
		}
		if (this.jsType === JsType.CLASSIC && (match = line.match(this.matchClassicObj))) {
			this.setObj(match[1]);
			this.setNameId(match[1], match[2]);
			return;
		}
		if ((match = line.match(this.matchObj))) {
			this.setObj(match[1]);
			this.setNameId(match[1], match[1]);
			return;
		}
		if ((match = line.match(this.matchClassNameId))) {
			this.setNameId(match[2], match[1]);
			return;
		}
		if ((match = line.match(this.matchEnumConstructs))) {
			const enumeration = this.enums.get(match[1]);
			if (enumeration) {
				enumeration.constructs = match[2];
				return;
			}
		}
		if ((match = line.match(this.matchStaticArr))) {
			const value = this.readFunctionBody(match[2]);
			this.setStaticVar(match[1], match[2], `(function($this) {${value}}(this))`);
			return;
		}
		if ((match = line.match(this.matchStaticFunc))) {
			const className = match[1];
			const name = match[2];
			const args = this.parseArgs(match[3]);
			const body = this.readFunctionBody(name);
			if (className === "window") {
				return;
			}
			this.traceType(`${className}.${name}(${args}) {${this.countLines(body)}}`);
			this.traceBody(body);
			this.ensureClass(className).methods[name] = {
				name,
				args,
				body,
				isStatic: true,
			};
			return;
		}
		if ((match = line.match(this.matchStaticVar))) {
			if (match[2] === "__name__") {
				return;
			}
			this.setStaticVar(match[1], match[2], match[3]);
			return;
		}
		if ((match = line.match(this.matchEnum))) {
			const name = match[1];
			this.enums.set(name, {
				name,
				nameId: match[2],
				body: this.readFunctionBody(name),
				constructs: null,
			});
		}
	}

	setConstructor(name, args) {
		const fieldName = "new";
		const klass = this.ensureClass(name);
		const func = {
			name: fieldName,
			args,
			body: this.readFunctionBody(fieldName),
		};
		klass.name = name;
		klass.methods[fieldName] = func;
		this.traceType(`${name}(${args}).new {${this.countLines(func.body)}}`);
		this.traceBody(func.body);
		this.currentClass = klass;
	}

	setObj(name) {
		const klass = this.ensureClass(name);
		klass.name = name;
		this.traceType(`Class ${name} {}`);
		this.currentClass = klass;
	}

	setNameId(name, nameId) {
		const klass = this.classes.get(name);
		if (!klass) {
			this.traceSkip(`Skip ${name} id ${nameId}`);
			return;
		}
		klass.nameId = nameId;
	}

	setStaticVar(className, field, value) {
		const klass = this.ensureClass(className);
		this.traceType(`${className}.${field} = ${this.minString(value)}`);
		klass.staticVars[field] = value;
	}

	ensureClass(name) {
		let klass = this.classes.get(name);
		if (!klass) {
			klass = {
				name,
				methods: Object.create(null),
				staticVars: Object.create(null),
			};
			this.classes.set(name, klass);
		}
		return klass;
	}

	readFunctionBody(fieldName) {
		let body = "";
		let section = BodySection.CODE;
		let level = 0;

		while (this.num < this.lines.length) {
			const line = this.lines[this.num];
			let lineStart = 0;
			let lineEnd = line.length;
			let i = 0;

			while (i < line.length) {
				const code = line.charCodeAt(i);

				switch (section) {
					case BodySection.CODE:
						if (code === "{".charCodeAt(0)) {
							if (level === 0) {
								lineStart = i + 1;
							}
							level += 1;
						} else if (code === "}".charCodeAt(0)) {
							level -= 1;
							if (level === 0) {
								lineEnd = i;
								break;
							}
							if (level < 0) {
								throw new Error(`Field "${fieldName}" closed before been opened`);
							}
						} else if (code === "/".charCodeAt(0)) {
							const next = line.charCodeAt(i + 1);
							if (next === "/".charCodeAt(0)) {
								section = BodySection.SINGLE_COMMENT;
							} else if (next === "*".charCodeAt(0)) {
								section = BodySection.MULTI_COMMENT;
							}
							if (section !== BodySection.CODE) {
								i += 1;
							}
						} else if (code === "'".charCodeAt(0)) {
							section = BodySection.SINGLE_QUOTES;
						} else if (code === "\"".charCodeAt(0)) {
							section = BodySection.DOUBLE_QUOTES;
						} else if (code === "`".charCodeAt(0)) {
							section = BodySection.BACKTICKS;
						}
						break;
					case BodySection.SINGLE_COMMENT:
						if (i === line.length - 1) {
							section = BodySection.CODE;
						}
						break;
					case BodySection.MULTI_COMMENT:
						if (code === "*".charCodeAt(0) && line.charCodeAt(i + 1) === "/".charCodeAt(0)) {
							section = BodySection.CODE;
							i += 1;
						}
						break;
					case BodySection.SINGLE_QUOTES:
						if (code === "\\".charCodeAt(0)) {
							i += 1;
						} else if (code === "'".charCodeAt(0)) {
							section = BodySection.CODE;
						}
						break;
					case BodySection.DOUBLE_QUOTES:
						if (code === "\\".charCodeAt(0)) {
							i += 1;
						} else if (code === "\"".charCodeAt(0)) {
							section = BodySection.CODE;
						}
						break;
					case BodySection.BACKTICKS:
						if (code === "\\".charCodeAt(0)) {
							i += 1;
						} else if (code === "`".charCodeAt(0)) {
							section = BodySection.CODE;
						}
						break;
				}

				i += 1;
			}

			if (body.length > 0 && lineEnd === line.length) {
				body += "\n";
			}
			body += line.substring(lineStart, lineEnd);
			if (level === 0 && section === BodySection.CODE) {
				break;
			}
			this.num += 1;
		}

		return body;
	}

	parseMethods(line) {
		if (this.currentClass == null) {
			this.mode = ParseMode.REGULAR;
			this.traceSkip(`Skip method parsing without current class: ${line}`);
			return;
		}

		const match = line.match(this.matchFunc);
		if (match) {
			const name = match[1];
			const args = this.parseArgs(match[2]);
			const body = this.readFunctionBody(name);
			this.traceType(`function ${name}(${args}) {${this.countLines(body)}}`);
			this.traceBody(body);
			this.currentClass.methods[name] = { name, args, body };
			return;
		}

		if (line === "};" || line === "});") {
			this.traceType(`} (${this.currentClass.name})`);
			this.mode = ParseMode.REGULAR;
			this.currentClass = null;
		}
	}

	findPrototypeClass(line) {
		const index = line.indexOf(".prototype");
		if (index === -1) {
			return this.currentClass;
		}
		return this.classes.get(line.substring(0, index).trim()) ?? null;
	}

	parseArgs(args) {
		return args === "" ? [] : args.split(",");
	}

	makeDiffTo(file) {
		if (this.jsType !== file.jsType) {
			return [{
				type: "fullReload",
				reason: `JS output mode changed from ${this.getJsType()} to ${file.getJsType()}`,
			}];
		}
		const result = [];
		for (const klass of file.classes.values()) {
			this.compareClass(klass, result);
		}
		for (const enumeration of file.enums.values()) {
			this.compareEnum(enumeration, result);
		}
		for (const klass of this.classes.values()) {
			if (!file.classes.has(klass.name) && klass.nameId != null) {
				console.log(`Delete class: ${klass.nameId}`);
				result.push({
					type: "deleteClass",
					className: klass.nameId,
					classId: klass.name,
				});
			}
		}
		for (const enumeration of this.enums.values()) {
			if (!file.enums.has(enumeration.name)) {
				console.log(`Delete enum: ${enumeration.nameId}`);
				result.push({
					type: "deleteEnum",
					name: enumeration.name,
					nameId: enumeration.nameId,
				});
			}
		}
		return result;
	}

	compareClass(klass, result) {
		const className = klass.nameId;
		const old = this.classes.get(klass.name);
		if (!old) {
			console.log(`New class: ${className}`);
			result.push({ type: "addClass", klass: serializeKlass(klass) });
			return;
		}

		if (old.nameId !== klass.nameId || old.parent !== klass.parent || old.interfaces !== klass.interfaces) {
			console.log(`${className}: replacing class shape`);
			result.push({ type: "addClass", klass: serializeKlass(klass) });
			return;
		}

		for (const key of mergeKeys(old.staticVars, klass.staticVars)) {
			const value = old.staticVars[key];
			const newValue = klass.staticVars[key];
			if (typeof newValue === "undefined") {
				console.log(`${className}: delete static var ${key}`);
				result.push({
					type: "deleteStaticVar",
					className,
					name: key,
				});
				continue;
			}
			if (value !== newValue) {
				console.log(`${className}: static var ${key} value: ${this.minString(newValue)}`);
				result.push({
					type: "staticVar",
					className,
					name: key,
					value: newValue,
				});
			}
		}

		for (const key of mergeKeys(old.methods, klass.methods)) {
			const value = old.methods[key];
			let newValue = klass.methods[key];
			if (!sameFunc(value, newValue)) {
				console.log(`${className}: func ${key}() value: ${this.minString(String(newValue))}`);
				if (newValue == null) {
					result.push({
						type: "deleteFunc",
						className,
						name: value.name,
						isStatic: !!value.isStatic,
					});
					continue;
				}
				if (newValue.name === "new") {
					result.push({
						type: "constructor",
						classId: klass.name,
						className,
						func: newValue,
					});
				} else {
					result.push({
						type: "func",
						className,
						func: newValue,
					});
				}
			}
		}
	}

	compareEnum(enumeration, result) {
		const old = this.enums.get(enumeration.name);
		if (!old) {
			console.log(`New enum: ${enumeration.nameId}`);
			result.push({ type: "addEnum", enumeration });
			return;
		}
		if (old.body !== enumeration.body || old.constructs !== enumeration.constructs) {
			console.log(`New enum body: ${this.minString(enumeration.body)}`);
			result.push({ type: "addEnum", enumeration });
		}
	}

	minString(value) {
		if (value == null) {
			return "null";
		}
		if (value.length < 23) {
			return value;
		}
		return value.slice(0, 10) + "..." + value.slice(-10);
	}

	countLines(value) {
		return value.split("\n").length;
	}
}

function mergeKeys(left, right) {
	const keys = new Set(Object.keys(left));
	for (const key of Object.keys(right)) {
		keys.add(key);
	}
	return [...keys];
}

function serializeKlass(klass) {
	return {
		name: klass.name,
		nameId: klass.nameId,
		parent: klass.parent,
		interfaces: klass.interfaces,
		methods: { h: { ...klass.methods } },
		staticVars: { h: { ...klass.staticVars } },
	};
}

function sameFunc(left, right) {
	if (left == null || right == null) {
		return left === right;
	}
	if (left.name !== right.name || left.body !== right.body || left.isStatic !== right.isStatic) {
		return false;
	}
	if (left.args.length !== right.args.length) {
		return false;
	}
	for (let i = 0; i < left.args.length; i += 1) {
		if (left.args[i] !== right.args[i]) {
			return false;
		}
	}
	return true;
}

function formatError(error) {
	if (error == null) {
		return "null";
	}
	return error.stack || error.message || String(error);
}

module.exports = {
	Server,
	Parser,
};
