package s.system.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class ShaderMacro {
	#if macro
	public static function build() {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass()?.get();

		if (cls == null || cls.isAbstract)
			return fields;

		var tp = {pack: cls.pack, name: cls.name}
		fields.push({
			name: "shader",
			access: [APrivate, AStatic],
			kind: FProp("default", "never", TPath(tp), macro new $tp()),
			pos: cls.pos
		});
		return fields;
	}
	#end
}
