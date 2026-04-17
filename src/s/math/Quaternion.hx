package s.math;

import s.math.Vec4;
import s.math.SMath;

@:forward.new
@:forward(x, y, z, w)
extern abstract Quaternion(Vec4) from Vec4 to Vec4 {
	public var length(get, set):Float;

	// Axis has to be normalized
	public static inline function fromAxisAngle(axis:Vec3, radians:Float):Quaternion {
		var q:Quaternion = new Quaternion();
		q.w = Math.cos(radians * 0.5);
		q.x = q.y = q.z = Math.sin(radians * 0.5);
		q.x *= axis.x;
		q.y *= axis.y;
		q.z *= axis.z;
		return q;
	}

	public inline function slerp(t:Float, q:Quaternion) {
		var dot = this.dot(q);

		if (dot > 1 - epsilon) {
			var result:Quaternion = q.add((sub(q)).scaled(t));
			result.normalize();
			return result;
		}
		if (dot < 0)
			dot = 0;
		if (dot > 1)
			dot = 1;

		var theta0:Float = Math.acos(dot);
		var theta:Float = theta0 * t;

		var q2:Quaternion = q.sub(scaled(dot));
		q2.normalize();

		var result:Quaternion = scaled(Math.cos(theta)).add(q2.scaled(Math.sin(theta)));

		result.normalize();

		return result;
	}

	// TODO: This should be multiplication
	public inline function rotated(b:Quaternion):Quaternion {
		var q:Quaternion = new Quaternion();
		q.w = this.w * b.w - this.x * b.x - this.y * b.y - this.z * b.z;
		q.x = this.w * b.x + this.x * b.w + this.y * b.z - this.z * b.y;
		q.y = this.w * b.y + this.y * b.w + this.z * b.x - this.x * b.z;
		q.z = this.w * b.z + this.z * b.w + this.x * b.y - this.y * b.x;
		q.normalize();
		return q;
	}

	public inline function scaled(scale:Float):Quaternion {
		return new Quaternion(this.x * scale, this.y * scale, this.z * scale, this.w * scale);
	}

	public inline function scale(scale:Float) {
		this.x *= scale;
		this.y *= scale;
		this.z *= scale;
		this.w *= scale;
	}

	public inline function matrix():Mat4 {
		var s:Float = 2.0;

		var xs:Float = this.x * s;
		var ys:Float = this.y * s;
		var zs:Float = this.z * s;
		var wx:Float = this.w * xs;
		var wy:Float = this.w * ys;
		var wz:Float = this.w * zs;
		var xx:Float = this.x * xs;
		var xy:Float = this.x * ys;
		var xz:Float = this.x * zs;
		var yy:Float = this.y * ys;
		var yz:Float = this.y * zs;
		var zz:Float = this.z * zs;

		return new Mat4(1 - (yy + zz), xy - wz, xz + wy, 0, xy + wz, 1 - (xx + zz), yz - wx, 0, xz - wy, yz + wx, 1 - (xx + yy), 0, 0, 0, 0, 1);
	}

	// For adding a (scaled) axis-angle representation of a quaternion
	public inline function addVector(vec:Vec3):Quaternion {
		var result:Quaternion = new Quaternion(this.x, this.y, this.z, this.w);
		var q1:Quaternion = new Quaternion(0, vec.x, vec.y, vec.z);

		q1 = q1.mult(result);

		result.x += q1.x * 0.5;
		result.y += q1.y * 0.5;
		result.z += q1.z * 0.5;
		result.w += q1.w * 0.5;
		return result;
	}

	public inline function add(q:Quaternion):Quaternion
		return @:privateAccess Vec4.add(this, q);

	public inline function sub(q:Quaternion):Quaternion
		return @:privateAccess Vec4.sub(this, q);

	// TODO: Check again, but I think the code in Kore is wrong
	public inline function mult(r:Quaternion):Quaternion {
		var q:Quaternion = new Quaternion();
		q.x = this.w * r.x + this.x * r.w + this.y * r.z - this.z * r.y;
		q.y = this.w * r.y - this.x * r.z + this.y * r.w + this.z * r.x;
		q.z = this.w * r.z + this.x * r.y - this.y * r.x + this.z * r.w;
		q.w = this.w * r.w - this.x * r.x - this.y * r.y - this.z * r.z;
		return q;
	}

	public inline function normalize()
		scale(1.0 / length);

	public inline function dot(q:Quaternion)
		return this.x * q.x + this.y * q.y + this.z * q.z + this.w * q.w;

	public inline function getEulerAngles(A1:Int, A2:Int, A3:Int, S:Int = 1, D:Int = 1):Vec3 {
		var result:Vec3 = new Vec3();

		var Q:Array<Float> = new Array<Float>();
		Q[0] = this.x;
		Q[1] = this.y;
		Q[2] = this.z;

		var ww:Float = this.w * this.w;

		var Q11:Float = Q[A1] * Q[A1];
		var Q22:Float = Q[A2] * Q[A2];
		var Q33:Float = Q[A3] * Q[A3];

		var psign:Float = -1;

		var SingularityRadius:Float = 0.0000001;
		var PiOver2:Float = Math.PI / 2.0;

		// Determine whether even permutation
		if (((A1 + 1) % 3 == A2) && ((A2 + 1) % 3 == A3)) {
			psign = 1;
		}

		var s2:Float = psign * 2.0 * (psign * this.w * Q[A2] + Q[A1] * Q[A3]);

		if (s2 < -1 + SingularityRadius) { // South pole singularity
			result.x = 0;
			result.y = -S * D * PiOver2;
			result.z = S * D * Math.atan2(2 * (psign * Q[A1] * Q[A2] + this.w * Q[A3]), ww + Q22 - Q11 - Q33);
		} else if (s2 > 1 - SingularityRadius) { // North pole singularity
			result.x = 0;
			result.y = S * D * PiOver2;
			result.z = S * D * Math.atan2(2 * (psign * Q[A1] * Q[A2] + this.w * Q[A3]), ww + Q22 - Q11 - Q33);
		} else {
			result.x = -S * D * Math.atan2(-2 * (this.w * Q[A1] - psign * Q[A2] * Q[A3]), ww + Q33 - Q11 - Q22);
			result.y = S * D * Math.asin(s2);
			result.z = S * D * Math.atan2(2 * (this.w * Q[A3] - psign * Q[A1] * Q[A2]), ww + Q11 - Q22 - Q33);
		}

		return result;
	}

	inline function get_length():Float
		return this.length();

	inline function set_length(value:Float):Float {
		if (length == 0)
			return 0;
		var mul = value / length;
		this.x *= mul;
		this.y *= mul;
		this.z *= mul;
		return value;
	}
}
