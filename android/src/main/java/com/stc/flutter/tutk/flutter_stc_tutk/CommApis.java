
package com.stc.flutter.tutk.flutter_stc_tutk;

import android.os.Handler;
import android.os.Message;

import com.tutk.IOTC.AVAPIs;
import com.tutk.IOTC.IOTCAPIs;

import com.tutk.IOTC.TutkLoctlCommand;

import java.util.Arrays;

public class CommApis extends IOTCAPIs {


    public static int ms_nIOTCInit = IOTCAPIs.IOTC_ER_TIMEOUT;

    private int nSID = -1;
    protected String m_strUID;
    protected int avIndex = -1;

    private boolean isStartVideo = false;


    private Handler handler;

    public CommApis() {

    }

    public int initIOTC() {
        if (ms_nIOTCInit != IOTCAPIs.IOTC_ER_NoERROR) {
            ms_nIOTCInit = IOTC_Initialize2(0);
            return ms_nIOTCInit;
        }
        return 0;
    }

    private void intiAVAPI(String uid, String deviceSN) {
        int media_chanel;
        while (true) {
            AVAPIs.avInitialize(8);
            int sid = IOTCAPIs.IOTC_Get_SessionID();
            nSID = sid;
            if (sid < 0) {
                System.out.printf("IOTC_Get_SessionID error code [%d]\n", sid);
                return;
            }
            int ret = IOTCAPIs.IOTC_Connect_ByUID_Parallel(uid, sid);
            System.out.printf("Step 2: call IOTC_Connect_ByUID_Parallel(%s).......\n", uid);
            if (ret < 0) {
                System.out.printf("IOTC_Connect_ByUID_Parallel error code [%d]\n", ret);
                return;
            }
            ret = IOTCAPIs.IOTC_Session_Channel_ON(nSID, 0);
            if (ret < 0) {
                System.out.printf("IOTC_Session_Channel_ON error code [%d]\n", ret);
                return;
            }
            media_chanel = IOTCAPIs.IOTC_Session_Get_Free_Channel(nSID);
            if (media_chanel < 0) {
                System.out.printf("IOTC_Session_Get_Free_Channel get free channel failed...!!\n");
                return;
            } else {
                System.out.printf("Step 3: call IOTC_Session_Get_Free_Channel(%d) ret = %d\n", sid, media_chanel);
                int loginResult = TutkLoctlCommand.login(sid, media_chanel, "admin", "888888");
                avIndex = loginResult;
                break;
            }
        }
        if (avIndex >= 0) {
            int startLiveVideoResult = TutkLoctlCommand.startLiveVideo(nSID, media_chanel, deviceSN);
            if (startLiveVideoResult >= 0) {
                System.out.printf("Step 5: 播放视频指令发送成功(%d) ret = %d\n", nSID, startLiveVideoResult);

            } else {
                System.out.printf("Step 5: 播放视频指令发送失败(%d) ret = %d\n", nSID, startLiveVideoResult);
            }
            if (startIpcamStream(avIndex)) {
                Thread videoThread = new Thread(new VideoThread(avIndex, handler),
                        "Video Thread");
                videoThread.start();
                try {
                    videoThread.join();
                } catch (InterruptedException e) {
                    System.out.println(e.getMessage());
                    return;
                }
                isStartVideo = true;
            } else {
                IOTCAPIs.IOTC_Session_Close(nSID);
                unInitIOTC();
            }
            AVAPIs.avClientStop(avIndex);
            System.out.printf("avClientStop OK\n");
            IOTCAPIs.IOTC_Session_Close(nSID);
            System.out.printf("IOTC_Session_Close OK\n");
            AVAPIs.avDeInitialize();
            IOTCAPIs.IOTC_DeInitialize();
            System.out.printf("StreamClient exit...\n");

        }
    }

    public void unInitIOTC() {
        if (!isStartVideo) {
            return;
        }
        if (ms_nIOTCInit == IOTCAPIs.IOTC_ER_NoERROR) {
            IOTC_DeInitialize();
            ms_nIOTCInit = IOTCAPIs.IOTC_ER_TIMEOUT;
        }
    }


    public void stopSess() {
        if (!isStartVideo) {
            return;
        }
        IOTC_Connect_Stop();
    }


    void start(String strUID, String deviceSN, Handler handler) {
        m_strUID = strUID;
        this.handler = handler;
        intiAVAPI(m_strUID, deviceSN);
    }


    private static boolean startIpcamStream(int avIndex) {
        AVAPIs av = new AVAPIs();
        int ret = av.avSendIOCtrl(avIndex, AVAPIs.IOTYPE_INNER_SND_DATA_DELAY,
                new byte[2], 2);
        if (ret < 0) {
            System.out.printf("start_ipcam_stream failed[%d]\n", ret);
            return false;
        }

        int IOTYPE_USER_IPCAM_START = 0x1FF;
        ret = av.avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_START,
                new byte[8], 8);
        if (ret < 0) {
            System.out.printf("start_ipcam_stream failed[%d]\n", ret);
            return false;
        }

        int IOTYPE_USER_IPCAM_AUDIOSTART = 0x300;
        ret = av.avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_AUDIOSTART,
                new byte[8], 8);
        if (ret < 0) {
            System.out.printf("start_ipcam_stream failed[%d]\n", ret);
            return false;
        }
        return true;
    }

    public static class VideoThread implements Runnable {
        static final int VIDEO_BUF_SIZE = 100000;
        static final int FRAME_INFO_SIZE = 16;

        private int avIndex;

        private Handler handler;

        public VideoThread(int avIndex, Handler handler) {
            this.avIndex = avIndex;
            this.handler = handler;
        }

        @Override
        public void run() {
            System.out.printf("[%s] avIndex\n",
                    avIndex);
            System.out.printf("[%s] Start\n",
                    Thread.currentThread().getName());

            AVAPIs av = new AVAPIs();
            byte[] frameInfo = new byte[FRAME_INFO_SIZE];
            byte[] videoBuffer = new byte[VIDEO_BUF_SIZE];
            int[] outBufSize = new int[1];
            int[] outFrameSize = new int[1];
            int[] outFrmInfoBufSize = new int[1];
            while (true) {
                int[] frameNumber = new int[1];
                int ret = av.avRecvFrameData2(avIndex, videoBuffer,
                        VIDEO_BUF_SIZE, outBufSize, outFrameSize,
                        frameInfo, FRAME_INFO_SIZE,
                        outFrmInfoBufSize, frameNumber);
                if (ret == AVAPIs.AV_ER_DATA_NOREADY) {
                    System.out.printf("[%s] Video data not ready[%d]\n",
                            Thread.currentThread().getName(), frameNumber[0]);
                    try {
                        Thread.sleep(30);
                        continue;
                    } catch (InterruptedException e) {
                        System.out.println(e.getMessage());
                        break;
                    }
                } else if (ret == AVAPIs.AV_ER_LOSED_THIS_FRAME) {
                    System.out.printf("[%s] Lost video frame number[%d]\n",
                            Thread.currentThread().getName(), frameNumber[0]);
                    continue;
                } else if (ret == AVAPIs.AV_ER_INCOMPLETE_FRAME) {
                    System.out.printf("[%s] Incomplete video frame number[%d]\n",
                            Thread.currentThread().getName(), frameNumber[0]);
                    continue;
                } else if (ret == AVAPIs.AV_ER_SESSION_CLOSE_BY_REMOTE) {
                    System.out.printf("[%s] AV_ER_SESSION_CLOSE_BY_REMOTE\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == AVAPIs.AV_ER_REMOTE_TIMEOUT_DISCONNECT) {
                    System.out.printf("[%s] AV_ER_REMOTE_TIMEOUT_DISCONNECT\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == IOTC_ER_INVALID_SID) {
                    System.out.printf("[%s] Session cant be used anymore\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == AVAPIs.AV_ER_INVALID_SID) {
                    System.out.printf("[%s] Session cant be used anymore\n",
                            Thread.currentThread().getName());
                    break;
                }

                System.out.printf("成功获取视频帧数据",
                        Thread.currentThread().getName() + "\n");
                Message msg = Message.obtain();
                msg.arg1 = 0;
                msg.arg2 = 0;
                msg.what = 0;
                msg.obj = Arrays.copyOfRange(videoBuffer, 0, ret);

                handler.sendMessage(msg);

                // Now the data is ready in videoBuffer[0 ... ret - 1]
                // Do something here
            }

            System.out.printf("[%s] Exit\n",
                    Thread.currentThread().getName());
        }
    }

    public static class AudioThread implements Runnable {
        static final int AUDIO_BUF_SIZE = 1024;
        static final int FRAME_INFO_SIZE = 16;

        private int avIndex;

        public AudioThread(int avIndex) {
            this.avIndex = avIndex;
        }

        @Override
        public void run() {
            System.out.printf("[%s] Start\n",
                    Thread.currentThread().getName());

            AVAPIs av = new AVAPIs();
            byte[] frameInfo = new byte[FRAME_INFO_SIZE];
            byte[] audioBuffer = new byte[AUDIO_BUF_SIZE];
            while (true) {
                int ret = av.avCheckAudioBuf(avIndex);

                if (ret < 0) {
                    // Same error codes as below
                    System.out.printf("[%s] avCheckAudioBuf() failed: %d\n",
                            Thread.currentThread().getName(), ret);
                    break;
                } else if (ret < 3) {
                    try {
                        Thread.sleep(120);
                        continue;
                    } catch (InterruptedException e) {
                        System.out.println(e.getMessage());
                        break;
                    }
                }

                int[] frameNumber = new int[1];
                ret = av.avRecvAudioData(avIndex, audioBuffer,
                        AUDIO_BUF_SIZE, frameInfo, FRAME_INFO_SIZE,
                        frameNumber);

                if (ret == AVAPIs.AV_ER_SESSION_CLOSE_BY_REMOTE) {
                    System.out.printf("[%s] AV_ER_SESSION_CLOSE_BY_REMOTE\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == AVAPIs.AV_ER_REMOTE_TIMEOUT_DISCONNECT) {
                    System.out.printf("[%s] AV_ER_REMOTE_TIMEOUT_DISCONNECT\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == AVAPIs.AV_ER_INVALID_SID) {
                    System.out.printf("[%s] Session cant be used anymore\n",
                            Thread.currentThread().getName());
                    break;
                } else if (ret == AVAPIs.AV_ER_LOSED_THIS_FRAME) {
                    //System.out.printf("[%s] Audio frame losed\n",
                    //        Thread.currentThread().getName());
                    continue;
                }

                // Now the data is ready in audioBuffer[0 ... ret - 1]
                // Do something here
            }

            System.out.printf("[%s] Exit\n",
                    Thread.currentThread().getName());
        }
    }

}
