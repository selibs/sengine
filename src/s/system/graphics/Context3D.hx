package s.system.graphics;

import kha.arrays.Int32Array;
import kha.arrays.Float32Array;
import kha.graphics4.Graphics;
import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.system.Texture;
import s.system.math.Vec2;
import s.system.math.Vec3;
import s.system.math.Vec4;
import s.system.math.Vec4I;
import s.system.math.Vec3I;
import s.system.math.Vec2I;
import s.system.math.Mat3;
import s.system.math.Mat4;
import s.system.math.SMath;
import s.system.resource.Image;

@:forward(begin, clear, flush, end, scissor, disableScissor, setPipeline, setIndexBuffer, setVertexBuffer, setVertexBuffers, setTextureParameters)
extern abstract Context3D(Graphics) from Graphics {
	public inline function setBool(location:ConstantLocation, value:Bool) {
		this.setBool(location, value);
	}

	public inline function setInt(location:ConstantLocation, value:Int) {
		this.setInt(location, value);
	}

	overload public inline function setInt2(location:ConstantLocation, value1:Int, value2:Int) {
		this.setInt2(location, value1, value2);
	}

	overload public inline function setInt2(location:ConstantLocation, value:Vec2I) {
		setInt2(location, value.x, value.y);
	}

	overload public inline function setInt3(location:ConstantLocation, value1:Int, value2:Int, value3:Int) {
		this.setInt3(location, value1, value2, value3);
	}

	overload public inline function setInt3(location:ConstantLocation, value:Vec3I) {
		setInt3(location, value.x, value.y, value.z);
	}

	overload public inline function setInt4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int) {
		this.setInt4(location, value1, value2, value3, value4);
	}

	overload public inline function setInt4(location:ConstantLocation, value:Vec4I) {
		setInt4(location, value.x, value.y, value.z, value.w);
	}

	public inline function setInts(location:ConstantLocation, value:Int32Array) {
		this.setInts(location, value);
	}

	public inline function setFloat(location:ConstantLocation, value:Float) {
		this.setFloat(location, value);
	}

	overload public inline function setFloat2(location:ConstantLocation, value1:Float, value2:Float) {
		this.setFloat2(location, value1, value2);
	}

	overload public inline function setFloat2(location:ConstantLocation, value:Vec2) {
		setFloat2(location, value.x, value.y);
	}

	overload public inline function setFloat3(location:ConstantLocation, value1:Float, value2:Float, value3:Float) {
		this.setFloat3(location, value1, value2, value3);
	}

	overload public inline function setFloat3(location:ConstantLocation, value:Vec3) {
		setFloat3(location, value.x, value.y, value.z);
	}

	overload public inline function setFloat4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float) {
		this.setFloat4(location, value1, value2, value3, value4);
	}

	overload public inline function setFloat4(location:ConstantLocation, value:Vec4) {
		setFloat4(location, value.x, value.y, value.z, value.w);
	}

	public inline function setFloats(location:ConstantLocation, value:Float32Array) {
		this.setFloats(location, value);
	}

	overload public inline function setVec2(location:ConstantLocation, value:Vec2) {
		this.setVector2(location, value);
	}

	overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float) {
		setVec2(location, vec2(value1, value2));
	}

	overload public inline function setVec3(location:ConstantLocation, value:Vec3) {
		this.setVector3(location, value);
	}

	overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float) {
		setVec3(location, vec3(value1, value2, value3));
	}

	overload public inline function setVec4(location:ConstantLocation, value:Vec4) {
		this.setVector4(location, value);
	}

	overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float) {
		setVec4(location, vec4(value1, value2, value3, value4));
	}

	overload public inline function setMat3(location:ConstantLocation, value:Mat3) {
		this.setMatrix3(location, value);
	}

	overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3) {
		setMat3(location, mat3(value1, value2, value3));
	}

	overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float, a12:Float,
			a22:Float) {
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));
	}

	overload public inline function setMat4(location:ConstantLocation, value:Mat4) {
		this.setMatrix(location, value);
	}

	overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4) {
		setMat4(location, mat4(value1, value2, value3, value4));
	}

	overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float, a31:Float,
			a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float) {
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));
	}

	public inline function setTexture(unit:TextureUnit, texture:Image, ?parameters:TextureParameters) {
		this.setTexture(unit, texture);
		if (parameters != null)
			this.setTextureParameters(unit, parameters.uAddressing ?? Clamp, parameters.vAddressing ?? Clamp, parameters.minificationFilter ?? PointFilter,
				parameters.magnificationFilter ?? PointFilter, parameters.mipmapFilter ?? NoMipFilter);
		else
			this.setTextureParameters(unit, Clamp, Clamp, PointFilter, PointFilter, NoMipFilter);
	}

	public inline function draw(start:Int = 0, count:Int = -1) {
		this.drawIndexedVertices(start, count);
	}

	public inline function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		this.drawIndexedVerticesInstanced(instanceCount, start, count);
	}
}
