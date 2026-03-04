package s2d.macro;

import haxe.macro.Compiler;
#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class ElementMacro {
	public static var shortcuts(default, null):Map<String, String> = [];
	static var initialized = false;
	static var collectorsInstalled = false;

	public static function init() {
		ensureInitialized(true);
	}

	public static function collectShortcuts() {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass()?.get();
		if (cls == null)
			return fields;

		registerClassShortcuts(cls);

		return fields;
	}

	public static function build() {
		ensureInitialized(false);
		var fields = Context.getBuildFields();

		for (field in fields) {
			if (field.meta == null)
				continue;
			for (m in field.meta)
				if (m.name == ":ui.markup") {
					try {
						buildMarkup(field);
					} catch (e:Dynamic) {
						Context.error("Failed to build markup: " + Std.string(e), field.pos);
					}
					break;
				}
		}

		return fields;
	}

	static function ensureInitialized(installCollectors:Bool) {
		if (!initialized) {
			initialized = true;
			indexShortcutsFromSources();
		}
		if (installCollectors && !collectorsInstalled) {
			collectorsInstalled = true;
			Compiler.addGlobalMetadata("", "@:build(s2d.macro.ElementMacro.collectShortcuts())");
		}
	}

	static function registerClassShortcuts(cls:ClassType) {
		var moduleName = cls.module.substr(cls.module.lastIndexOf(".") + 1);
		var typePath = cls.module + (moduleName != cls.name ? "." + cls.name : "");
		registerShortcutsFromMeta(typePath, cls.meta.extract(":ui.shortcut"));
		registerShortcutsFromMeta(typePath, cls.meta.extract(":ui.short"));
	}

	static function registerShortcutsFromMeta(typePath:String, metas:Array<MetadataEntry>) {
		for (meta in metas)
			for (p in meta.params ?? []) {
				var shortcut = extractShortcutExpr(p);
				if (shortcut != null)
					addShortcut(shortcut, typePath, p.pos);
			}
	}

	static function extractShortcutExpr(p:Expr):String {
		return switch p.expr {
			case EConst(CIdent(s)), EConst(CString(s)):
				s;
			case EField(e, field):
				var base = extractShortcutExpr(e);
				base == null ? null : base + "." + field;
			default:
				Context.warning("Invalid expression. Expected name", p.pos);
				null;
		}
	}

	static function addShortcut(shortcut:String, typePath:String, pos:Position) {
		var prev = shortcuts.get(shortcut);
		if (prev == null || prev == typePath)
			shortcuts.set(shortcut, typePath);
		else
			Context.warning('Shortcut "$shortcut" is already taken by $prev', pos);
	}

	static function indexShortcutsFromSources() {
		for (classPath in Context.getClassPath()) {
			if (!FileSystem.exists(classPath) || !FileSystem.isDirectory(classPath))
				continue;
			indexShortcutsInDir(Path.normalize(classPath), Path.normalize(classPath));
		}
	}

	static function indexShortcutsInDir(root:String, dir:String) {
		for (entry in FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (FileSystem.isDirectory(path)) {
				indexShortcutsInDir(root, path);
				continue;
			}
			if (!StringTools.endsWith(entry, ".hx"))
				continue;
			indexShortcutsInFile(root, path);
		}
	}

	static function indexShortcutsInFile(root:String, filePath:String) {
		var content = try File.getContent(filePath) catch (_:Dynamic) return;
		if (content.indexOf("@:ui.short") == -1)
			return;

		var rel = filePath.substr(root.length);
		if (rel.length > 0 && (rel.charAt(0) == "/" || rel.charAt(0) == "\\"))
			rel = rel.substr(1);
		rel = rel.split("\\").join("/");
		if (!StringTools.endsWith(rel, ".hx"))
			return;

		var modulePath = rel.substr(0, rel.length - 3).split("/").join(".");
		var moduleName = modulePath.substr(modulePath.lastIndexOf(".") + 1);
		var re = ~/@:ui\.(?:shortcut|short)\s*\(([\s\S]*?)\)\s*(?:@[^\r\n]*\s*)*(?:private\s+)?(?:class|interface|enum|abstract)\s+([A-Za-z_][A-Za-z0-9_]*)/gm;
		var offset = 0;
		while (re.matchSub(content, offset)) {
			var rawParams = re.matched(1);
			var typeName = re.matched(2);
			var typePath = modulePath + (typeName != moduleName ? "." + typeName : "");
			for (shortcut in parseShortcuts(rawParams, filePath))
				addShortcut(shortcut, typePath, Context.makePosition({
					file: filePath,
					min: 0,
					max: 0
				}));
			var m = re.matchedPos();
			offset = m.pos + m.len;
		}
	}

	static function parseShortcuts(rawParams:String, filePath:String):Array<String> {
		var result:Array<String> = [];
		var validIdent = ~/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$/;
		var filePos = Context.makePosition({
			file: filePath,
			min: 0,
			max: 0
		});
		for (part in splitTopLevel(rawParams)) {
			var token = StringTools.trim(part);
			if (token == "")
				continue;
			if (token.charAt(0) == "\"" && token.charAt(token.length - 1) == "\"") {
				token = token.substr(1, token.length - 2);
			} else if (!validIdent.match(token)) {
				Context.warning('Invalid @:ui.shortcut argument "$token" in $filePath', filePos);
				continue;
			}
			result.push(token);
		}
		return result;
	}

	static function splitTopLevel(raw:String):Array<String> {
		var parts:Array<String> = [];
		var start = 0;
		var paren = 0;
		var brace = 0;
		var bracket = 0;
		var inString = false;
		var escaped = false;
		var i = 0;
		while (i < raw.length) {
			var c = raw.charAt(i);
			if (inString) {
				if (escaped)
					escaped = false;
				else if (c == "\\")
					escaped = true;
				else if (c == "\"")
					inString = false;
				i++;
				continue;
			}
			switch c {
				case "\"":
					inString = true;
				case "(":
					paren++;
				case ")":
					paren = paren > 0 ? paren - 1 : 0;
				case "{":
					brace++;
				case "}":
					brace = brace > 0 ? brace - 1 : 0;
				case "[":
					bracket++;
				case "]":
					bracket = bracket > 0 ? bracket - 1 : 0;
				case ",":
					if (paren == 0 && brace == 0 && bracket == 0) {
						parts.push(raw.substring(start, i));
						start = i + 1;
					}
				default:
			}
			i++;
		}
		parts.push(raw.substr(start));
		return parts;
	}

	static function buildMarkup(field:Field) {
		var i = 0;
		var stack:Array<Expr> = [macro this];

		function transform(expr:Expr) {
			function buildEl(meta:MetadataEntry, expr:Expr, pos:Position) {
				var elName = "__el" + i++;
				var elRef = macro $i{elName};
				var elCls = try {
					var n = shortcuts.get(meta.name) ?? meta.name;
					switch Context.getType(n) {
						case TInst(t, params):
							var cls = t.get();
							var m = cls.module;
							var name = m.substring(m.lastIndexOf(".") + 1);
							{
								pack: cls.pack,
								name: name,
								sub: name != cls.name ? cls.name : null
							}
						default:
							throw "Invalid element class: " + n;
					}
				} catch (e) {
					Context.warning(Std.string(e), pos);
					return EBlock([]);
				}

				var parent = stack[stack.length - 1];
				stack.push(elRef);

				var elExprs:Array<Expr> = flatten(macro {
					parent = $parent;
					@:pos(pos) var $elName = new $elCls();
					parent.addChild($elRef);
				});

				for (p in meta.params ?? [])
					switch p.expr {
						case EBinop(OpAssign, e1, e2):
							switch e1.expr {
								case EConst(CIdent(s)):
									elExprs.push(macro @:pos(e1.pos) $elRef.$s = $e2);
								default:
									Context.warning("Invalid attribute", p.pos);
							}
						case EObjectDecl(fields):
							for (f in fields) {
								var s = f.field;
								elExprs.push(macro @:pos(f.expr.pos) $elRef.$s = ${f.expr});
							}
						default:
							Context.warning("Invalid operation", p.pos);
					}
				elExprs = elExprs.concat(flatten(transform(expr)));
				stack.pop();

				return EBlock(elExprs);
			}

			var def = expr.expr;
			if (def != null)
				expr.expr = switch def {
					case EBlock(exprs):
						EBlock(exprs.map(e -> transform(e)));
					case EIf(econd, eif, eelse):
						EIf(econd, transform(eif), eelse != null ? transform(eelse) : null);
					case EFor(it, e):
						EFor(it, transform(e));
					case EWhile(econd, e, normalWhile):
						EWhile(econd, transform(e), normalWhile);
					case ESwitch(e, cases, edef):
						ESwitch(e, cases.map(c -> {
							values: c.values,
							guard: c.guard,
							expr: transform(c.expr)
						}), edef != null ? transform(edef) : null);
					case EMeta(m, e) if (m.name.charAt(0) != ":"):
						buildEl(m, e, expr.pos);
					default:
						expr.expr;
				}
			return expr;
		}

		switch field.kind {
			case FFun(f):
				if (f.expr != null) {
					f.expr = concat(macro {
						var parent = this.parent;
					}, transform(f.expr));
				}
			default:
				throw "Field must be function";
		}
	}

	static function concat(e1:Expr, e2:Expr) {
		var e = flatten(e1).concat(flatten(e2));
		if (e.length > 1)
			return macro $b{e};
		return e[0];
	}

	static function flatten(expr:Expr):Array<Expr> {
		return switch expr.expr {
			case EBlock(exprs):
				exprs;
			default:
				[expr];
		}
	}
}
#end
