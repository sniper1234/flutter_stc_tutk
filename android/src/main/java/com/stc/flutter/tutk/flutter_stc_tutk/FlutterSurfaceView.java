package com.stc.flutter.tutk.flutter_stc_tutk;

import android.content.Context;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import com.tutk.client.FFMPEG.Decoder;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class FlutterSurfaceView implements PlatformView {

    private final SurfaceView surfaceView;

    private final MethodChannel methodChannel;


    FlutterSurfaceView(Context context, BinaryMessenger messenger, int id, Map<String, Object> params, MethodChannel methodChannel) {
        surfaceView = new SurfaceView(context);
        surfaceView.setZOrderOnTop(true);
        surfaceView.setBackgroundResource(R.color.color_black);
        surfaceView.getHolder().setType(SurfaceHolder.SURFACE_TYPE_NORMAL);
        this.methodChannel = methodChannel;
    }


    @Override
    public View getView() {
        return surfaceView;
    }

    @Override
    public void dispose() {
        methodChannel.setMethodCallHandler(null);
    }


}
