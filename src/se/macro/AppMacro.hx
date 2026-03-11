package se.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;
#end

class AppMacro {
	#if macro
	public static function build() {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass()?.get();
		if (cls == null)
			return fields;

		var options = {
			expr: EObjectDecl([
				for (m in cls.meta.get())
					if (m.name.substr(0, 5) == ":app.") {
						var params = m.params ?? [];
						if (params.length == 0)
							Context.warning("Parameter expected", m.pos);
						{
							field: m.name.substr(5),
							expr: switch params[0].expr {
								case EBinop(OpAssign, e1, e2):
									{
										expr: EObjectDecl([
											for (p in params)
												switch p.expr {
													case EBinop(OpAssign, e1, e2):
														switch e1.expr {
															case EConst(CIdent(s)):
																{field: s, expr: e2}
															default:
																Context.error("Invalid expression", p.pos);
																null;
														}
													default:
														Context.error("Invalid expression", p.pos);
														null;
												}
										]),
										pos: m.pos
									}
								default:
									params[0];
							}
						}
					}
			]),
			pos: Context.currentPos()
		}

		var mainFun = null;
		for (field in fields)
			if (field.name == "main") {
				switch field.kind {
					case FFun(f):
						mainFun = f;
					default:
				}
				break;
			}
		if (mainFun == null) {
			mainFun = {args: []};
			fields.push({
				access: [AStatic],
				name: "main",
				kind: FFun(mainFun),
				pos: Context.currentPos()
			});
		}

		if (mainFun.expr == null)
			mainFun.expr = macro {};

		mainFun.expr = macro se.App.start($options, (window:se.Window) -> ${mainFun.expr});

		return fields;
	}
	#end
}
