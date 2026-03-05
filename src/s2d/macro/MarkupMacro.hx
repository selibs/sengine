package s2d.macro;

import haxe.macro.Compiler;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

class MarkupMacro {
	#if macro
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

		Compiler.addGlobalMetadata("", "@:build(s2d.macro.MarkupMacro.build())", true, true, true);
	}

	public static function useShortcut(name:String, type:String) {
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

	static function buildMarkup(field:Field) {
		var i = 0;
		var stack:Array<Expr> = [];

		function transform(expr:Expr) {
			function buildEl(meta:MetadataEntry, expr:Expr, pos:Position, ?name:String, ?ref:Expr) {
				var elName = name ?? "__el" + i++;
				var elRef = ref ?? macro $i{elName};
				var elCls = try {
					var n = shortcuts.get(meta.name) ?? meta.name;
					switch Context.getType(n).toComplexType() {
						case TPath(tp):
							tp;
						default:
							throw "Invalid element class: " + n;
					}
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
						buildEl(m, e, expr.pos);
					case EVars(vars):
						EBlock(vars.map(v -> {
							var n = v.name;
							if (v.expr == null)
								return macro var $n;
							return switch v.expr.expr {
								case EMeta(s, e):
									{
										expr: buildEl(s, e, v.expr.pos, n),
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
										buildEl(m, e, e2.pos, s, e1);
									case EField(e, field):
										buildEl(m, e, e2.pos, null, e1);
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

		switch field.kind {
			case FFun(f):
				if (f.args.length > 0)
					Context.warning("Markup functions can't have arguments", field.pos);
				f.args = [
					{
						name: "parent",
						type: macro :s2d.Element
					}
				];

				if (f.expr != null) {
					var exprs = transform(f.expr);
					f.expr = macro $b{exprs};
					trace(f.expr.toString());
				}
			default:
				throw "Field must be function";
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
