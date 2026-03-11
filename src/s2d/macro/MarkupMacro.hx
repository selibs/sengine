package s2d.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class ExprError extends haxe.Exception {
	public var expr:Expr;

	public function new(expr:Expr, ?message:String) {
		super(message ?? "Invalid expression");
		this.expr = expr;
	}

	public function warn() {
		Context.warning('$message: ${expr.toString()}', expr.pos);
	}
}
#end

class MarkupMacro {
	#if macro
	static var reserved = ["style", "use", "all"];
	static var stylesheets:Map<String, Map<String, Array<Expr>>>;

	public static var shortcuts(default, null):Map<String, String> = [
		"element" => "s2d.Element",
		"drawable" => "s2d.DrawableElement",
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
						try {
							buildStylesheet(field);
						} catch (er:ExprError) {
							er.warn();
							fields.remove(field);
						}
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
		var stack:Array<Expr> = [macro parent];

		function transform(expr:Expr) {
			function addEl(meta:MetadataEntry, expr:Expr, pos:Position, ?name:String, ?ref:Expr) {
				var elName = name ?? "__el" + i++;
				var elRef = ref ?? macro @:pos(pos) $i{elName};
				var elCls = try {
					getTypePath(meta.name);
				} catch (e)
					Context.error(Std.string(e), pos);

				var elExprs = [];
				var ctor = macro new $elCls($a{meta.params ?? []});
				if (ref == null)
					elExprs.push(macro @:pos(pos) var $elName = $ctor);
				else
					elExprs.push(macro @:pos(pos) $elRef = $ctor);

				elExprs.push(macro ${stack[stack.length - 1]}.addChild($elRef));
				stack.push(elRef);
				elExprs = elExprs.concat(transform(expr));
				stack.pop();

				return EBlock(elExprs);
			}

			var def = expr.expr;
			if (def != null)
				expr.expr = switch def {
					case EConst(CIdent(s)) if (s.charAt(0) == "$"):
						return transform(macro @:pos(expr.pos) $p{[stack[stack.length - 1].toString(), s.substr(1)]});
					case EMeta(m, e) if (m.name.charAt(0) != ":"):
						switch m.name {
							case "use":
								(macro ${stack[stack.length - 1]}.useStylesheet($e)).expr;
							default:
								addEl(m, e, expr.pos);
						}
					case EVars(vars):
						EBlock(vars.map(v -> {
							var n = v.name;
							if (v.expr == null)
								return macro @:pos(expr.pos) var $n;
							return switch v.expr.expr {
								case EMeta(s, e):
									{
										expr: addEl(s, e, v.expr.pos, n),
										pos: v.expr.pos
									}
								default:
									macro @:pos(v.expr.pos) var $n = ${v.expr};
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

		if (expr != null) {
			var f = {
				args: args,
				expr: block(transform(expr)),
				ret: macro :Void
			}
			field.kind = FFun(f);
		}
	}

	static function buildStylesheet(field:Field) {
		function buildStyle(meta:MetadataEntry, expr:Expr, mExpr:Expr):Array<Expr> {
			var substyles = [];

			function getName(expr:Expr) {
				return switch expr.expr {
					case EConst((CIdent(s))):
						switch s {
							case "$":
								meta.name;
							default: s;
						}
					case EField(e, field, kind):
						getName(e) + "." + field;
					default:
						null;
				}
			}

			function prop(expr:Expr) {
				return switch expr.expr {
					case EConst(CIdent(s)):
						macro @:pos(expr.pos) $v{s} => Exists;
					case EBinop(OpAssign, e1, e2):
						var name = getName(e1);
						if (name == null)
							throw new ExprError(expr, "Name expected");
						macro @:pos(e1.pos) $v{name} => Equals($e2);
					default:
						throw new ExprError(expr);
				}
			}

			function rule(expr:Expr) {
				var name = getName(expr);
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
								throw new ExprError(expr);
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
							default:
								throw new ExprError(expr);
						}
					case EArrayDecl(values):
						var props = [
							for (v in values)
								try {
									prop(v);
								} catch (er:ExprError) {
									er.warn();
									continue;
								}
						];
						macro @:pos(expr.pos) Properties([$a{props}]);
					case ECall(e, params):
						switch e.expr {
							case EConst(CIdent(s)):
								switch s {
									case "not" if (params.length == 1):
										macro @:pos(expr.pos) Not(${rule(params[0])});
									case "or" if (params.length == 2):
										macro @:pos(expr.pos) Or(${rule(params[0])}, ${rule(params[1])});
									case "and" if (params.length == 2):
										macro @:pos(expr.pos) And(${rule(params[0])}, ${rule(params[1])});
									case "any":
										macro @:pos(expr.pos) Any([$a{params.map(rule)}]);
									case "all":
										macro @:pos(expr.pos) All([$a{params.map(rule)}]);
									default:
										throw new ExprError(expr, 'Unknown operation "$s"');
								}
							default:
								throw new ExprError(expr, "Operation name expected");
						}
					default:
						throw new ExprError(expr);
				}
			}

			function body(type:String, expr:Expr) {
				function replace(e:Expr) {
					return e.map(e -> switch e.expr {
						case EConst(CIdent(s)) if (s.charAt(0) == "$"):
							macro @:pos(e.pos) $p{["e"].concat(s.substr(1).split("."))};
						default:
							replace(e);
					});
				}

				return switch expr.expr {
					case EBlock(exprs):
						var t = getType(type);
						var fields = [macro var e:$t = cast e];
						for (e in exprs)
							switch e.expr {
								case EMeta(m, e) if (m.name.charAt(0) != ":"):
									try {
										for (s in buildStyle(m, e, expr))
											substyles.push(s);
									} catch (er:ExprError)
										er.warn();
								default:
									fields.push(replace(e));
							}
						macro e -> ${block(fields)};
					default:
						throw new ExprError(expr);
				}
			}

			var params = meta.params ?? [];
			if (params.length < 2) {
				var selector = macro Type($p{getTypeName(meta.name).split(".")});
				if (params.length == 1)
					selector = macro And($selector, ${rule(params[0])});
				substyles.push(macro new s2d.Style($selector, ${body(meta.name, expr)}));
			} else
				throw new ExprError(mExpr, "Expected only 1 selector");

			return substyles;
		}

		var expr = extractExpr(field);
		switch expr.expr {
			case EBlock(exprs):
				var styles = [];
				for (ex in exprs)
					try {
						switch ex.expr {
							case EMeta(m, e) if (m.name.charAt(0) != ":"):
								styles = styles.concat(buildStyle(m, e, ex));
							default:
								throw new ExprError(ex);
						}
					} catch (er:ExprError)
						er.warn();
				field.kind = FVar(macro :s2d.Style.Stylesheet, macro @:pos(expr.pos) $a{styles});
			default:
				throw new ExprError(expr);
		}
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
