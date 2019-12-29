package com.stc.flutter.tutk.flutter_stc_tutk;

import android.content.Context;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class FlutterStcTutkFactory extends PlatformViewFactory {

//    private final BinaryMessenger messenger;

//    private final MethodChannel methodChannel;

//    private FlutterSurfaceView flutterSurfaceView;

    private SurfaceView surfaceView;

    public FlutterStcTutkFactory(MessageCodec<Object> objectMessageCodec, SurfaceView surfaceView) {
        super(objectMessageCodec);
//        this.messenger = messenger;
//        this.methodChannel = methodChannel;
        this.surfaceView = surfaceView;


    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
//        Map<String, Object> params = (Map<String, Object>) o;
//        flutterSurfaceView = new FlutterSurfaceView(context, messenger, i, params, methodChannel);
//        return flutterSurfaceView;
        surfaceView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        surfaceView.setZOrderOnTop(true);
        surfaceView.setBackgroundResource(R.color.color_fcfbfb);

        surfaceView.getHolder().setType(SurfaceHolder.SURFACE_TYPE_NORMAL);

        return new PlatformView() {
            @Override
            public View getView() {
                return surfaceView;
            }

            @Override
            public void dispose() {

            }
        };
    }

    public SurfaceView getFlutterSurfaceView() {
        return surfaceView;
    }


}
