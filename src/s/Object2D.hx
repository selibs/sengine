package s;

import s.math.Vec2;
import s.math.Mat3;

abstract class Object2D<T:Object2D<T>> extends Object<T> {
	@:attr(transformLocal) final transform:Mat3 = new Mat3();

	@:signal function update(object:T):Void;

	public var translationX(get, set):Float;
	public var translationY(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var rotation(get, set):Float;
	public var shearX(get, set):Float;
	public var shearY(get, set):Float;

	@:attr(hierarchy) public var z:Float = 0.0;

	extern overload public inline function setTranslation(x:Float, y:Float) {
		translationX = x;
		translationY = y;
	}

	extern overload public inline function setTranslation(value:Vec2)
		setTranslation(value.x, value.y);

	extern overload public inline function setScale(x:Float, y:Float) {
		scaleX = x;
		scaleY = y;
	}

	extern overload public inline function setScale(value:Vec2)
		setScale(value.x, value.y);

	extern overload public inline function setRotation(value:Float)
		rotation = value;

	extern overload public inline function setShear(x:Float, y:Float) {
		shearX = x;
		shearY = y;
	}

	extern overload public inline function setShear(value:Vec2)
		setShear(value.x, value.y);

	extern overload public inline function translate(x:Float, y:Float) {
		transform *= Mat3.translation(x, y);
		transformDirty = true;
	}

	extern overload public inline function translate(value:Vec2)
		translate(value.x, value.y);

	extern overload public inline function translate(value:Float)
		translate(value, value);

	extern overload public inline function scale(x:Float, y:Float) {
		transform *= Mat3.scale(x, y);
		transformDirty = true;
	}

	extern overload public inline function scale(value:Vec2)
		scale(value.x, value.y);

	extern overload public inline function scale(value:Float)
		scale(value, value);

	extern overload public inline function rotate(value:Float) {
		transform *= Mat3.rotation(value);
		transformDirty = true;
	}

	extern overload public inline function shear(x:Float, y:Float) {
		transform *= Mat3.shear(x, y);
		transformDirty = true;
	}

	extern overload public inline function shear(value:Vec2)
		shear(value.x, value.y);

	@:slot(update)
	function updateZ(_)
		if (zDirty)
			parent?.insertChild(cast this);

	function insertChild(child:T) {
		var list = @:privateAccess children.list;
		var ind = list.indexOf(child);

		list.remove(child);
		for (i in 0...list.length)
			if (list[i].z > child.z) {
				list.insert(i, child);
				return;
			}
		list.push(child);

		if (ind != list.indexOf(child))
			children.dirty = true;
	}

	inline function get_translationX():Float
		return transform._20;

	inline function set_translationX(value:Float) {
		transformDirty = true;
		return transform._20 = value;
	}

	inline function get_translationY():Float
		return transform._21;

	inline function set_translationY(value:Float) {
		transformDirty = true;
		return transform._21 = value;
	}

	inline function get_scaleX():Float
		return local00(rotation);

	inline function set_scaleX(value:Float) {
		transformDirty = true;
		setLinear(rotation, value, scaleY, shearX, shearY);
		return value;
	}

	inline function get_scaleY():Float
		return local11(rotation);

	inline function set_scaleY(value:Float) {
		transformDirty = true;
		setLinear(rotation, scaleX, value, shearX, shearY);
		return value;
	}

	inline function get_rotation():Float
		return Math.atan2(transform._10 - transform._01, transform._00 + transform._11);

	inline function set_rotation(value:Float) {
		transformDirty = true;
		setLinear(value, scaleX, scaleY, shearX, shearY);
		return value;
	}

	inline function get_shearX():Float
		return local10(rotation);

	inline function set_shearX(value:Float) {
		transformDirty = true;
		setLinear(rotation, scaleX, scaleY, value, shearY);
		return value;
	}

	inline function get_shearY():Float
		return local01(rotation);

	inline function set_shearY(value:Float) {
		transformDirty = true;
		setLinear(rotation, scaleX, scaleY, shearX, value);
		return value;
	}

	inline function setLinear(rotation:Float, scaleX:Float, scaleY:Float, shearX:Float, shearY:Float) {
		var c = Math.cos(rotation);
		var s = Math.sin(rotation);

		transform._00 = c * scaleX - s * shearX;
		transform._10 = s * scaleX + c * shearX;
		transform._01 = c * shearY - s * scaleY;
		transform._11 = s * shearY + c * scaleY;
	}

	inline function local00(rotation:Float):Float {
		var c = Math.cos(rotation);
		var s = Math.sin(rotation);
		return c * transform._00 + s * transform._10;
	}

	inline function local10(rotation:Float):Float {
		var c = Math.cos(rotation);
		var s = Math.sin(rotation);
		return -s * transform._00 + c * transform._10;
	}

	inline function local01(rotation:Float):Float {
		var c = Math.cos(rotation);
		var s = Math.sin(rotation);
		return c * transform._01 + s * transform._11;
	}

	inline function local11(rotation:Float):Float {
		var c = Math.cos(rotation);
		var s = Math.sin(rotation);
		return -s * transform._01 + c * transform._11;
	}
}
