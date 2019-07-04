package com.stc.flutter.tutk.flutter_stc_tutk;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.view.SurfaceView;

import com.tutk.client.FFMPEG.Decoder;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterStcTutkPlugin
 */
public class FlutterStcTutkPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

    private final Context context;

    private final Activity activity;

    protected CommApis m_commApis;

    private static FlutterStcTutkFactory flutterStcTutkFactory;

    private Decoder decoder;


    private FlutterStcTutkPlugin(Activity activity, Context context) {
        this.context = context;
        this.activity = activity;
        m_commApis = new CommApis();
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_stc_tutk");

        //传入Activity
        final FlutterStcTutkPlugin plugin = new FlutterStcTutkPlugin(registrar.activity(), registrar.activeContext());
        channel.setMethodCallHandler(plugin);


        registrar.addActivityResultListener(plugin);
        registrar.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int i, String[] strings, int[] ints) {
                return false;
            }
        });

        flutterStcTutkFactory = new FlutterStcTutkFactory(registrar.messenger(), channel);

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
                startLiveVideo(uid, deviceSN);
                break;
            case "stopLiveVideo": //停止视频

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
        decoder = new Decoder((SurfaceView) flutterStcTutkFactory.getFlutterSurfaceView().getView());
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
        m_commApis.start(uid, decoder.getHandler());

    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent intent) {
        return false;
    }
}
