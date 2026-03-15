package s2d;

import se.math.Vec2;
import se.math.Mat3;
import se.math.SMath;

abstract class Object2D<This:Object2D<This>> extends se.Object<This> {
	@:attr public var visible:Bool = true;
	@:attr public var z(default, set):Float = 0;

	public var transform:Mat3 = Mat3.identity();
	public var translationX(get, set):Float;
	public var translationY(get, set):Float;
	public var translation(get, set):Vec2;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scale(get, set):Vec2;
	public var rotation(get, set):Float;

	public function new() {
		super();
	}

	@:slot(childAdded)
	override function __childAdded__(child:This) {
		insertChild(child);
		super.__childAdded__(child);
	}

	function insertChild(child:This) {
		var c = @:privateAccess children.list;
		c.remove(child);
		for (i in 0...c.length)
			if (c[i].z > child.z) {
				c.insert(i, child);
				return;
			}
		c.push(child);
	}

	function set_z(value:Float):Float {
		if (value != z) {
			z = value;
			if (parent != null)
				parent.insertChild(cast this);
		}
		return z;
	}

	extern overload public inline function translate(x:Float, y:Float) {
		transform *= Mat3.translation(x, y);
	}

	extern overload public inline function translate(value:Vec2) {
		translate(value.x, value.y);
	}

	extern overload public inline function translate(value:Float) {
		translate(value, value);
	}

	extern overload public inline function upscale(x:Float, y:Float) {
		transform *= Mat3.scale(x, y);
	}

	extern overload public inline function upscale(value:Vec2) {
		upscale(value.x, value.y);
	}

	extern overload public inline function upscale(value:Float) {
		upscale(value, value);
	}

	extern overload public inline function upscale(x:Float, y:Float, origin:Vec2) {
		translate(-origin.x, -origin.y);
		upscale(x, y);
		translate(origin.x, origin.y);
	}

	extern overload public inline function upscale(value:Vec2, origin:Vec2) {
		upscale(value.x, value.y, origin);
	}

	extern overload public inline function upscale(value:Float, origin:Vec2) {
		upscale(value, value, origin);
	}

	extern overload public inline function rotate(value:Float) {
		transform *= Mat3.rotation(value);
	}

	extern overload public inline function rotate(value:Float, origin:Vec2) {
		translate(-origin.x, -origin.y);
		rotate(value);
		translate(origin.x, origin.y);
	}

	inline function get_translationX():Float
		return transform._20;

	inline function set_translationX(value:Float)
		return transform._20 = value;

	inline function get_translationY():Float
		return transform._21;

	inline function set_translationY(value:Float)
		return transform._21 = value;

	function get_translation():Vec2
		return vec2(translationX, translationY);

	function set_translation(value:Vec2) {
		translationX = value.x;
		translationY = value.y;
		return value;
	}

	function get_scaleX():Float
		return Math.sqrt(transform._00 * transform._00 + transform._10 * transform._10);

	function set_scaleX(value:Float) {
		var s = scaleX;
		if (s != 0) {
			var d = value / s;
			transform._00 *= d;
			transform._10 *= d;
		} else {
			transform._00 = value;
			transform._10 = value;
		}
		return value;
	}

	function get_scaleY():Float
		return Math.sqrt(transform._01 * transform._01 + transform._11 * transform._11);

	function set_scaleY(value:Float) {
		var s = scaleY;
		if (s != 0) {
			var d = value / s;
			transform._01 *= d;
			transform._11 *= d;
		} else {
			transform._01 = value;
			transform._11 = value;
		}
		return value;
	}

	function get_scale():Vec2
		return vec2(scaleX, scaleY);

	function set_scale(value:Vec2) {
		scaleX = value.x;
		scaleY = value.y;
		return value;
	}

	function get_rotation():Float
		return Math.atan2(transform._10, transform._00);

	function set_rotation(value:Float) {
		var c = Math.cos(value);
		var s = Math.sin(value);
		var sx = scaleX;
		var sy = scaleY;

		transform._00 = c * sx;
		transform._10 = s * sx;
		transform._01 = -s * sy;
		transform._11 = c * sy;
		return value;
	}
}
