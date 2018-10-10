package io.xiaoyan.qrcode;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.Log;
import android.view.View;

import cn.bingoogolapple.qrcode.core.QRCodeView;
import cn.bingoogolapple.qrcode.zxing.ZXingView;

public class QRCodeActivity extends Activity implements QRCodeView.Delegate {

    public static final String EXTRA_RESULT = "extra_result";
    public static final String SCAN_TYPE = "scan_type";

    public static final int SCAN_TO_SHARE = 1;
    public static final int SCAN_TO_REQUEST = 2;

    private ZXingView mRequestView;
    private ZXingView mShareView;

    private int mScanType;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_qrcode_scan);
        mRequestView = findViewById(R.id.qrcode_scan_request);
        mShareView = findViewById(R.id.qrcode_scan_share);
        final Intent intent = getIntent();
        mScanType = intent.getIntExtra(SCAN_TYPE, 2);
        if (mScanType == SCAN_TO_REQUEST) {
            mRequestView.setDelegate(this);
            mRequestView.setVisibility(View.VISIBLE);
            mShareView.setVisibility(View.GONE);
        } else if (mScanType == SCAN_TO_SHARE) {
            mShareView.setDelegate(this);
            mShareView.setVisibility(View.VISIBLE);
            mRequestView.setVisibility(View.GONE);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mScanType == SCAN_TO_REQUEST) {
            mRequestView.startCamera();
            mRequestView.showScanRect();
            mRequestView.startSpot();
        } else if (mScanType == SCAN_TO_SHARE) {
            mShareView.startCamera();
            mShareView.showScanRect();
            mShareView.startSpot();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mScanType == SCAN_TO_REQUEST) {
            mRequestView.stopSpot();
            mRequestView.stopCamera();
        } else if (mScanType == SCAN_TO_SHARE) {
            mShareView.stopSpot();
            mShareView.stopCamera();
        }
    }

    @Override
    public void onScanQRCodeSuccess(String result) {
        if (mScanType == SCAN_TO_SHARE) {
            mShareView.stopSpot();
            mShareView.startSpot();
        } else {
            mRequestView.stopSpot();
            mRequestView.startSpot();
        }
        final Intent intent = new Intent();
        intent.putExtra(EXTRA_RESULT, result);
        setResult(Activity.RESULT_OK, intent);
        //finish();
    }

    @Override
    public void onScanQRCodeOpenCameraError() {
        Log.e("ERROR", "open camera error");
    }
}
