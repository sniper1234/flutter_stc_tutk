package com.tutk.client.FFMPEG;

import android.os.Handler;
import android.os.Looper;
import android.view.Surface;
import android.view.SurfaceView;

public class Decoder extends Thread {
    private SurfaceView surface;
    private Handler handler;
    private byte native_decoder[];

    public Decoder(SurfaceView surf) {
        surface = surf;
    }

    public Handler getHandler() {
        return handler;
    }

    public boolean Init() {
        native_decoder = new byte[8];
        if (!init(native_decoder)) {
            return false;
        }
        return true;
    }

    public boolean Deinit() {
        if (null == native_decoder) {
            return false;
        }
        deinit(native_decoder);
        return true;
    }

    public boolean Stop() {
        return true;
    }

    @Override
    public void run() {
        Looper.prepare();
        handler = new Handler() {
            public void handleMessage(android.os.Message msg) {
                byte frame[] = (byte[]) msg.obj;
                Surface sur = surface.getHolder().getSurface();
                if (null != sur) {
                    play(native_decoder, frame, msg.arg1, msg.arg2, msg.what, sur);
                }
            }

            ;
        };
        Looper.loop();
    }

    private native boolean init(byte ptr[]);

    private native void play(byte ptr[], byte frame[], int width, int height, int pts,
                             Surface surface);

    private native boolean deinit(byte ptr[]);

    static {
        System.loadLibrary("avcodec");
        System.loadLibrary("avutil");
        System.loadLibrary("avformat");
        System.loadLibrary("swscale");
        System.loadLibrary("native-lib");
    }
}
