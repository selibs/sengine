package s.ui.graphics.stage;

#if S2D_PP_BLOOM
import s.ui.graphics.stage.postprocessing.Bloom;
#end
#if S2D_PP_FISHEYE
import s.ui.graphics.stage.postprocessing.Fisheye;
#end
#if S2D_PP_FILTER
import s.ui.graphics.stage.postprocessing.Filter;
#end
#if S2D_PP_COMPOSITOR
import s.ui.graphics.stage.postprocessing.Compositor;
#end

@:dox(hide)
class PostProcessing {
	#if S2D_PP_BLOOM
	public static final bloom = new Bloom();
	#end
	#if S2D_PP_FISHEYE
	public static final fisheye = new Fisheye();
	#end
	#if S2D_PP_FILTER
	public static final filter = new Filter();
	#end
	#if S2D_PP_COMPOSITOR
	public static final compositor = new Compositor();
	#end
}
