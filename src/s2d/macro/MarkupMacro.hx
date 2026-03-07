package s2d.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

class MarkupMacro {
	#if macro
	static var reserved = ["style", "use", "all"];
	static var stylesheets:Map<String, Map<String, Array<Expr>>>;

	public static var shortcuts(default, null):Map<String, String> = [
		"element" => "s2d.Element",
		// controls
		"button" => "s2d.controls.Button",
		"input" => "s2d.controls.TextInput",
		// elements
		"canvas" => "s2d.elements.Canvas",
		"label" => "s2d.elements.Label",
		"positioner" => "s2d.elements.Positioner",
		"text" => "s2d.elements.Text",
		"edit" => "s2d.elements.TextEdit",
		// shapes
		"rectangle" => "s2d.elements.shapes.Rectangle",
		"rectangle.rounded" => "s2d.elements.shapes.RoundedRectangle",
		// layouts
		"box" => "s2d.layouts.BoxLayout",
		"vbox" => "s2d.layouts.VBoxLayout",
		"hbox" => "s2d.layouts.HBoxLayout",
		// widgets
		"image" => "s2d.widgets.ImageWidget",
		"progress" => "s2d.widgets.ProgressBar",
		"scroll" => "s2d.widgets.ScrollView",
		// stage
		"stage" => "s2d.Stage"
	];

	public static function init() {
		Compiler.registerCustomMetadata({
			metadata: ":ui.markup",
			doc: "A"
		});
		stylesheets = [];
		Compiler.addGlobalMetadata("", "@:build(s2d.macro.MarkupMacro.build())", true, true, true);
	}

	public static function useShortcut(name:String, type:String) {
		if (reserved.contains(name)) {
			Context.warning("Can't overwrite reserved shortcut `name`", Context.currentPos());
			return;
		}

		if (shortcuts.exists(name))
			Context.warning('Shortcut `$name -> ${shortcuts.get(name)}` will be overwritten to `$type`', Context.currentPos());
		shortcuts.set(name, type);
	}

	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			if (field.meta == null)
				continue;
			for (m in field.meta)
				switch m.name {
					case ":ui.markup":
						buildMarkup(field);
					case ":ui.style":
						var expr = extractExpr(field);
						expr = buildStylesheet(expr);
						field.kind = FVar(macro :s2d.Style.Stylesheet, expr);
				}
		}

		return fields;
	}

	static function getType(name:String) {
		return Context.getType(getTypeName(name)).toComplexType();
	}

	static function getTypePath(name:String) {
		switch getType(name) {
			case TPath(tp):
				return tp;
			default:
				throw "Invalid element class: " + name;
		}
	}

	static function getTypeName(name:String) {
		return shortcuts.get(name) ?? name;
	}

	static function buildMarkup(field:Field) {
		var i = 0;
		var stack:Array<Expr> = [];

		function transform(expr:Expr) {
			function addEl(meta:MetadataEntry, expr:Expr, pos:Position, ?name:String, ?ref:Expr) {
				var elName = name ?? "__el" + i++;
				var elRef = ref ?? macro $i{elName};
				var elCls = try {
					getTypePath(meta.name);
				} catch (e)
					Context.error(Std.string(e), pos);

				var attrs = [];
				var args = [];

				for (p in meta.params ?? []) {
					function pushAttr(name:String, value:Expr)
						if (name != null) {
							var fRef = elRef;
							for (f in name.split("."))
								fRef = macro $fRef.$f;

							var call = switch value.expr {
								case EMeta(s, e):
									value = e;
									s.name == "args";
								default:
									false;
							}
							var expr = if (call) switch value.expr {
								case EArrayDecl(values):
									macro $fRef($a{values});
								default:
									Context.warning("Expected an array of call arguments", value.pos);
									return;
							} else macro $fRef = $value;

							attrs.push(macro @:pos(p.pos) $expr);
						}

					switch p.expr {
						case EBinop(OpAssign, e1, e2):
							pushAttr(extractName(e1), e2);
						case EObjectDecl(fields):
							for (f in fields)
								pushAttr(f.field, f.expr);
						default:
							args.push(p);
					}
				}

				var elExprs = [];
				if (stack.length > 0)
					elExprs.push(macro parent = ${stack[stack.length - 1]});

				var ctor = macro new $elCls($a{args});
				if (ref == null)
					elExprs.push(macro var $elName = $ctor);
				else
					elExprs.push(macro $elRef = $ctor);
				elExprs.push(macro parent.addChild($elRef));
				elExprs = elExprs.concat(attrs);

				stack.push(elRef);
				elExprs = elExprs.concat(transform(expr));
				stack.pop();

				return EBlock(elExprs);
			}

			var def = expr.expr;
			if (def != null)
				expr.expr = switch def {
					case EMeta(m, e) if (m.name.charAt(0) != ":"):
						switch m.name {
							// case "style":
							// 	addStyle(styles, e);
							// 	(macro null).expr;
							case "use":
								(macro parent.useStylesheet($e)).expr;
							default:
								addEl(m, e, expr.pos);
						}
					case EVars(vars):
						EBlock(vars.map(v -> {
							var n = v.name;
							if (v.expr == null)
								return macro var $n;
							return switch v.expr.expr {
								case EMeta(s, e):
									{
										expr: addEl(s, e, v.expr.pos, n),
										pos: v.expr.pos
									}
								default:
									macro var $n = ${v.expr};
							}
						}));
					case EBinop(OpAssign, e1, e2):
						switch e2.expr {
							case EMeta(m, e):
								switch e1.expr {
									case EConst(CIdent(s)):
										addEl(m, e, e2.pos, s, e1);
									case EField(e, field):
										addEl(m, e, e2.pos, null, e1);
									default:
										(expr.map(e -> block(transform(e)))).expr;
								}
							default:
								(expr.map(e -> block(transform(e)))).expr;
						}
					default:
						(expr.map(e -> block(transform(e)))).expr;
				}

			return flatten(expr);
		}

		var expr = extractExpr(field);
		var args = switch field.kind {
			case FFun(f):
				f.args;
			default:
				[];
		}
		args.push({
			name: "parent",
			type: macro :s2d.Element
		});

		if (expr != null)
			field.kind = FFun({
				args: args,
				expr: block(transform(expr)),
				ret: macro :Void
			});
	}

	static function buildStylesheet(expr:Expr) {
		function rule(expr:Expr) {
			var name = extractName(expr);
			if (name != null)
				return macro @:pos(expr.pos) Type($p{getTypeName(name).split(".")});

			return switch expr.expr {
				case EConst(CString(s)):
					macro @:pos(expr.pos) Tag($expr);
				case EUnop(op, false, e):
					switch op {
						case OpNot:
							macro @:pos(expr.pos) Not(${rule(e)});
						case OpNegBits:
							macro @:pos(expr.pos) Object($e);
						default:
							throw "Invalid expression";
					}
				case EBinop(op, e1, e2):
					switch op {
						case OpOr:
							macro @:pos(expr.pos) Or(${rule(e1)}, ${rule(e2)});
						case OpAnd:
							macro @:pos(expr.pos) And(${rule(e1)}, ${rule(e2)});
						case OpLt:
							macro @:pos(expr.pos) And(${rule(e1)}, Parent(${rule(e2)}));
						case OpGt:
							macro @:pos(expr.pos) And(${rule(e1)}, Children(${rule(e2)}));
						case OpMod:
							macro @:pos(expr.pos) And(${rule(e1)}, Siblings(${rule(e2)}));
						case OpShr:
							macro @:pos(expr.pos) And(${rule(e1)}, Descendants(${rule(e2)}));
						default:
							throw "Invalid expression";
					}
				case ECall(e, params):
					switch e.expr {
						case EConst(CIdent(s)):
							switch s {
								case "not" if (params.length == 1):
									macro @:pos(expr.pos) Not(${rule(params[0])});
								case "any":
									macro @:pos(expr.pos) Any([$a{params.map(rule)}]);
								case "all":
									macro @:pos(expr.pos) All([$a{params.map(rule)}]);
								default:
									throw 'Unknown operation "$s"';
							}
						default:
							throw "Operation name expected";
					}
				default:
					throw "Invalid expression";
			}
		}

		function body(type:String, expr:Expr) {
			return switch expr.expr {
				case EBlock(exprs):
					var t = getType(type);
					var fields = [macro var e:$t = cast e];
					for (e in exprs)
						try {
							switch e.expr {
								case EBinop(OpAssign, e1, e2):
									var name = extractName(e1);
									if (name == null)
										throw "Invalid expression";
									e1.expr = (macro $p{["e"].concat(name.split("."))}).expr;
									fields.push(macro $e1 = $e2);
								default:
									throw "Invalid expression";
							}
						} catch (err)
							Context.reportError(err.message, e.pos);
					macro e -> ${block(fields)};
				default:
					throw "Invalid expression";
			}
		}

		function buildStyle(expr:Expr) {
			try {
				switch expr.expr {
					case EMeta(m, e) if (m.name.charAt(0) != ":"):
						var params = m.params ?? [];
						if (params.length < 2) {
							var selector = macro Type($p{getTypeName(m.name).split(".")});
							if (params.length == 1)
								selector = macro And($selector, ${rule(params[0])});
							return macro new s2d.Style($selector, ${body(m.name, e)});
						} else {
							throw "Expected only 1 selector";
						}
					default:
						throw "Invalid expression";
				}
			} catch (e) {
				Context.warning(e.message, expr.pos);
				return null;
			}
		}

		expr.expr = {
			switch expr.expr {
				case EBlock(exprs):
					EArrayDecl([
						for (e in exprs) {
							var s = buildStyle(e);
							if (s != null) s; else continue;
						}
					]);
				default:
					Context.warning("Invalid expression", expr.pos);
					(macro null).expr;
			}
		}
		return expr;
	}

	static function extractExpr(field:Field) {
		return switch field.kind {
			case FFun(f):
				f.expr;
			case FVar(t, e), FProp(_, _, t, e):
				e;
		}
	}

	static function extractName(expr:Expr):String {
		return switch expr.expr {
			case EConst(CIdent(s)), EConst(CString(s)):
				s;
			case EField(e, field):
				extractName(e) + "." + field;
			default:
				Context.warning("Name expected", expr.pos);
				null;
		}
	}

	static function concat(e1:Expr, e2:Expr) {
		return block(flatten(e1).concat(flatten(e2)));
	}

	static function block(exprs:Array<Expr>) {
		if (exprs.length > 1)
			return macro $b{exprs};
		return exprs[0];
	}

	static function flatten(expr:Expr):Array<Expr> {
		return switch expr.expr {
			case EBlock(exprs):
				exprs;
			default:
				[expr];
		}
	}
	#end
}
