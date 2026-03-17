package s.markup.graphics.stage;

#if S2D_PP_BLOOM
import s.markup.graphics.stage.postprocessing.Bloom;
#end
#if S2D_PP_FISHEYE
import s.markup.graphics.stage.postprocessing.Fisheye;
#end
#if S2D_PP_FILTER
import s.markup.graphics.stage.postprocessing.Filter;
#end
#if S2D_PP_COMPOSITOR
import s.markup.graphics.stage.postprocessing.Compositor;
#end

@:dox(hide)
class PostProcessing {
	#if S2D_PP_BLOOM
	public static var bloom(default, never) = new Bloom();
	#end
	#if S2D_PP_FISHEYE
	public static var fisheye(default, never) = new Fisheye();
	#end
	#if S2D_PP_FILTER
	public static var filter(default, never) = new Filter();
	#end
	#if S2D_PP_COMPOSITOR
	public static var compositor(default, never) = new Compositor();
	#end
}
