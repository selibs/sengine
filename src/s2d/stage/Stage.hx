package s2d.stage;

import se.Texture;
import se.math.Vec2;
import se.math.Mat3;
import se.math.SMath;
import se.graphics.RenderBuffer;
import s2d.DrawableElement;
import s2d.stage.Camera;
import s2d.stage.StageLayer;
import s2d.graphics.Drawers;

@:access(s2d.stage.objects.Object)
class Stage extends DrawableElement {
	var layers:Array<StageLayer> = [];
	var renderBuffer:RenderBuffer = new RenderBuffer();
	@:inject(updateViewProjection)
	var aspectRatio:Float = 1.0;
	var viewProjection:Mat3 = Mat3.identity();

	@:inject(updateViewProjection)
	public var stageScale:Float = 1.0;

	public var camera:Camera = new Camera();

	#if (S2D_LIGHTING_ENVIRONMENT == 1)
	@:isVar public var environmentMap(default, set):se.Assets.ImageAsset;

	function set_environmentMap(value) {
		if (value != null) {
			value.onAssetLoaded(asset -> (asset : Texture).generateMipmaps(4));
			environmentMap = value;
		}
		return value;
	}
	#end

	public function new() {
		super();

		#if (S2D_LIGHTING_ENVIRONMENT == 1)
		environmentMap = "default_emission";
		#end
	}

	public function addLayer(layer:StageLayer) {
		if (!layers.contains(layer))
			layers.push(layer);
	}

	public function removeLayer(layer:StageLayer) {
		layers.remove(layer);
	}

	public function local2WorldSpace(point:Vec2):Vec2 {
		return (inverse(viewProjection) * vec3(point, 1.0)).xy;
	}

	public function world2LocalSpace(point:Vec2):Vec2 {
		return (viewProjection * vec3(point, 1.0)).xy;
	}

	public function screen2LocalSpace(point:Vec2):Vec2 {
		return vec2(point.x / width, point.y / height) * 2.0 - 1.0;
	}

	public function local2ScreenSpace(point:Vec2):Vec2 {
		return vec2(point.x * width, point.y * height) * 0.5 - 0.5;
	}

	public function screen2WorldSpace(point:Vec2):Vec2 {
		return local2WorldSpace(screen2LocalSpace(point));
	}

	public function world2ScreenSpace(point:Vec2):Vec2 {
		return local2ScreenSpace(world2LocalSpace(point));
	}

	@:slot(widthChanged, heightChanged)
	function __syncSizeChanged__(_) {
		renderBuffer.resize(Std.int(width), Std.int(height));
		aspectRatio = width / height;
	}

	function updateViewProjection() {
		var projection;
		if (aspectRatio >= 1)
			projection = Mat3.orthogonalProjection(-stageScale * aspectRatio, stageScale * aspectRatio, -stageScale, stageScale);
		else
			projection = Mat3.orthogonalProjection(-stageScale, stageScale, -stageScale / aspectRatio, stageScale / aspectRatio);
		viewProjection.copyFrom(projection * camera.view);
	}

	function draw(target:Texture) {
		Drawers.stageRenderer.render(target, this);
	}
}
