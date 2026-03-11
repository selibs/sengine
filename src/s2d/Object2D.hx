package s2d;

import se.math.Vec2;
import se.math.Mat3;
import se.math.SMath;

abstract class Object2D<This:Object2D<This>> extends se.Object<This> {
	@:signal public var visible:Bool = true;
	@:signal @:isVar public var z(default, set):Float = 0;

	var globalTransform:Mat3 = Mat3.identity();

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

	public function zsorted() {
		var i = 0;
		while (i < children.length)
			if (children[i].z >= 0.0)
				break;
			else
				++i;
		if (i > 0)
			return {
				below: children.slice(0, i),
				above: children.slice(i)
			}
		return {
			below: [],
			above: children
		}
	}

	@:slot(parentChanged)
	function __parentChanged__(previous:This) {
		syncTransform();
	}

	@:slot(childAdded)
	override function __childAdded__(child:This) {
		super.__childAdded__(child);
		insertChild(child);
	}

	function insertChild(child:This) @:privateAccess {
		var c = children.list;
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

	function syncParentTransform():Void {
		globalTransform.copyFrom(parent.globalTransform * transform);
		for (c in children)
			c.syncParentTransform();
	}

	function syncTransform():Void {
		if (parent != null)
			globalTransform.copyFrom(parent.globalTransform * transform);
		else
			globalTransform.copyFrom(transform);
		for (c in children)
			c.syncParentTransform();
	}

	function applyTransform(m:Mat3, ?o:Vec2) {
		if (o == null)
			transform *= m;
		else
			transform *= Mat3.translation(-o.x, -o.y) * m * Mat3.translation(o.x, o.y);
		syncTransform();
	}

	extern overload public inline function translate(x:Float, y:Float) {
		transform *= Mat3.translation(x, y);
		syncTransform();
	}

	extern overload public inline function translate(value:Vec2) {
		translate(value.x, value.y);
	}

	extern overload public inline function translate(value:Float) {
		translate(value, value);
	}

	extern overload public inline function upscale(x:Float, y:Float, ?origin:Vec2) {
		applyTransform(Mat3.scale(x, y), origin);
	}

	extern overload public inline function upscale(value:Vec2, ?origin:Vec2) {
		upscale(value.x, value.y, origin);
	}

	extern overload public inline function upscale(value:Float, ?origin:Vec2) {
		upscale(value, value, origin);
	}

	public function rotate(value:Float, ?origin:Vec2) {
		applyTransform(Mat3.rotation(value), origin);
	}

	function get_translationX():Float {
		return transform._20;
	}

	function set_translationX(value:Float) {
		transform._20 = value;
		syncTransform();
		return value;
	}

	function get_translationY():Float {
		return transform._21;
	}

	function set_translationY(value:Float) {
		transform._21 = value;
		syncTransform();
		return value;
	}

	function get_translation():Vec2 {
		return vec2(translationX, translationY);
	}

	function set_translation(value:Vec2) {
		transform._20 = value.x;
		transform._21 = value.y;
		syncTransform();
		return value;
	}

	function get_scaleX():Float {
		return Math.sqrt(transform._00 * transform._00 + transform._10 * transform._10);
	}

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
		syncTransform();
		return value;
	}

	function get_scaleY():Float {
		return Math.sqrt(transform._01 * transform._01 + transform._11 * transform._11);
	}

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
		syncTransform();
		return value;
	}

	function get_scale():Vec2 {
		return vec2(scaleX, scaleY);
	}

	function set_scale(value:Vec2) {
		var sx = scaleX;
		if (sx != 0) {
			var d = value.x / sx;
			transform._00 *= d;
			transform._10 *= d;
		} else {
			transform._00 = value.x;
			transform._10 = value.x;
		}
		var sy = scaleY;
		if (sy != 0) {
			var d = value.y / sy;
			transform._01 *= d;
			transform._11 *= d;
		} else {
			transform._01 = value.y;
			transform._11 = value.y;
		}
		syncTransform();
		return value;
	}

	function get_rotation():Float {
		return Math.atan2(transform._10, transform._00);
	}

	function set_rotation(value:Float) {
		var c = Math.cos(value);
		var s = Math.sin(value);
		var sx = scaleX;
		var sy = scaleY;

		transform._00 = c * sx;
		transform._10 = s * sx;
		transform._01 = -s * sy;
		transform._11 = c * sy;

		syncTransform();
		return value;
	}
}
