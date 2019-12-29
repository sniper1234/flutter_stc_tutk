package com.stc.flutter.tutk.flutter_stc_tutk;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceView;
import android.widget.ImageView;

import com.tutk.client.FFMPEG.Decoder;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.view.TextureRegistry;

/**
 * FlutterStcTutkPlugin
 */
public class FlutterStcTutkPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {


    protected CommApis m_commApis;

    private static FlutterStcTutkFactory flutterStcTutkFactory;

    private Decoder decoder;

    private final Registrar flutterRegistrar;

    private TextureRegistry textureRegistry;
    private TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;
    private Surface surface;


    private FlutterStcTutkPlugin(Registrar flutterRegistrar) {
        this.flutterRegistrar = flutterRegistrar;
//        textureRegistry=flutterRegistrar.textures();

        m_commApis = new CommApis();
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_stc_tutk");

        //传入Activity
        final FlutterStcTutkPlugin plugin = new FlutterStcTutkPlugin(registrar);
        channel.setMethodCallHandler(plugin);


        registrar.addActivityResultListener(plugin);
        registrar.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int i, String[] strings, int[] ints) {
                return false;
            }
        });

        flutterStcTutkFactory = new FlutterStcTutkFactory(new StandardMessageCodec(), new SurfaceView(registrar.activeContext()));

        registrar
                .platformViewRegistry()
                .registerViewFactory(
                        "stc_video_player_view", flutterStcTutkFactory);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "startLiveVideo": //播放视频
                String uid = call.argument("uid");
                String deviceSN = call.argument("deviceSN");
//                textureRegistry = flutterRegistrar.textures();
//                surfaceTextureEntry = textureRegistry.createSurfaceTexture();
//                //通过一个刚刚创建的SurfaceTexure作为参数创建一个Surface
//                surface = new Surface(surfaceTextureEntry.surfaceTexture());

                startLiveVideo(uid, deviceSN);
                result.success(null);
                break;
            case "stopLiveVideo": //停止视频
                try {
                    m_commApis.stopSess();
                    m_commApis.unInitIOTC();
                } catch (Exception e) {
                    System.out.printf("关闭失败\n");
                }
                if (decoder != null) {
                    decoder.Deinit();
                }
                result.success(null);
                break;
            case "pauseLiveVideo": //暂停视频

                break;
            default:
                result.notImplemented();
                break;
        }
    }


    private void startLiveVideo(String uid, String deviceSN) {
        m_commApis.initIOTC();
        decoder = new Decoder(flutterStcTutkFactory.getFlutterSurfaceView());
        if (!decoder.Init()) {
            Log.e("tutk", "init decoder failed");
            return;
        }
        decoder.start();
        while (null == decoder.getHandler()) {
            try {
                Thread.sleep(10);
            } catch (Exception e) {
            }
        }
        m_commApis.start(uid, deviceSN, decoder.getHandler());

    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent intent) {
        return false;
    }
}
