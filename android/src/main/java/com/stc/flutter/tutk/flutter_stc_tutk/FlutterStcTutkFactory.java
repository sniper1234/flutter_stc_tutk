package com.stc.flutter.tutk.flutter_stc_tutk;

import android.content.Context;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class FlutterStcTutkFactory extends PlatformViewFactory {

    private final BinaryMessenger messenger;

    private final MethodChannel methodChannel;

    private FlutterSurfaceView flutterSurfaceView;

    public FlutterStcTutkFactory(BinaryMessenger messenger, MethodChannel methodChannel) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.methodChannel = methodChannel;

    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        Map<String, Object> params = (Map<String, Object>) o;
        flutterSurfaceView = new FlutterSurfaceView(context, messenger, i, params, methodChannel);
        return flutterSurfaceView;
    }

    public FlutterSurfaceView getFlutterSurfaceView() {
        return flutterSurfaceView;
    }


}
