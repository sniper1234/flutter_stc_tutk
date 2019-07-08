package com.tutk.IOTC;

public class TutkLoctlCommand {


    // Used to load the 'native-lib' library on application startup.
    static {
        System.loadLibrary("native-lib");
    }

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    public static native int login(int sid, int mediaChannel, String userName, String password);


    public static native int startLiveVideo(int sid, int mediaChannel,String deviceSN);

    public static native void stopAv(int sid, int currentAvIndex);


    public static native void receiveVideoThread(int avIndex);


}
