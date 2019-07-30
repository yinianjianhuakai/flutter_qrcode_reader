// Copyright (c) <2017> <Matheus Villela>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package com.matheusvillela.flutter.plugins.qrcodereader;

import android.app.Activity;
import android.content.Intent;
import android.graphics.PointF;
import android.os.Bundle;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import android.widget.TextView;

import com.dlazaro66.qrcodereaderview.QRCodeReaderView;


public class QRScanActivity extends Activity implements QRCodeReaderView.OnQRCodeReadListener {

    private boolean qrRead;
    private QRCodeReaderView view;
    public static String EXTRA_RESULT = "extra_result";
    public static String EXTRA_FOCUS_INTERVAL = "extra_focus_interval";
    public static String EXTRA_FORCE_FOCUS = "extra_force_focus";
    public static String EXTRA_TORCH_ENABLED = "extra_torch_enabled";
    public static String EXTRA_FRONT_CAMERA = "extra_front_camera";
    private ImageView scan_line, iv_finsh;
    private TextView my_qrcode, tv_chepaifu, tv_yuangongid, shoujiHaoMa;

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_qr_read);
        view = (QRCodeReaderView) findViewById(R.id.activity_qr_read_reader);
        scan_line = (ImageView) findViewById(R.id.scan_line);
        my_qrcode = (TextView) findViewById(R.id.my_qrcode);
        tv_chepaifu = (TextView) findViewById(R.id.tv_chepaifu);
        tv_yuangongid = (TextView) findViewById(R.id.tv_yuangongid);
        shoujiHaoMa = (TextView) findViewById(R.id.shouJiHaoMa);
        iv_finsh = (ImageView) findViewById(R.id.iv_finsh);
        iv_finsh.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
        if (QRCodeReaderPlugin.instance.qrCodeScene == QRCodeScene.fueling) {
            tv_chepaifu.setVisibility(View.GONE);//车牌付，VISIBLE显示，隐藏GONE
            tv_yuangongid.setVisibility(View.VISIBLE);//输入员工ID，VISIBLE显示，隐藏GONE
            my_qrcode.setVisibility(View.VISIBLE);
            shoujiHaoMa.setVisibility(View.GONE);

        } else if (QRCodeReaderPlugin.instance.qrCodeScene == QRCodeScene.fuelingWithPlateNumberPay) {
            tv_chepaifu.setVisibility(View.VISIBLE);//车牌付，VISIBLE显示，隐藏GONE
            tv_yuangongid.setVisibility(View.VISIBLE);//输入员工ID，VISIBLE显示，隐藏GONE
            my_qrcode.setVisibility(View.VISIBLE);
            shoujiHaoMa.setVisibility(View.GONE);
        } else if (QRCodeReaderPlugin.instance.qrCodeScene == QRCodeScene.bindingGasStation) {
            tv_chepaifu.setVisibility(View.GONE);//车牌付，VISIBLE显示，隐藏GONE
            tv_yuangongid.setVisibility(View.GONE);//输入员工ID，VISIBLE显示，隐藏GONE
            my_qrcode.setVisibility(View.GONE);
            shoujiHaoMa.setVisibility(View.GONE);
        } else if (QRCodeReaderPlugin.instance.qrCodeScene == QRCodeScene.nothing) {
            tv_chepaifu.setVisibility(View.GONE);//车牌付，VISIBLE显示，隐藏GONE
            tv_yuangongid.setVisibility(View.GONE);//输入员工ID，VISIBLE显示，隐藏GONE
            my_qrcode.setVisibility(View.GONE);
            shoujiHaoMa.setVisibility(View.GONE);
        } else if (QRCodeReaderPlugin.instance.qrCodeScene == QRCodeScene.phone) {
            tv_chepaifu.setVisibility(View.GONE);//车牌付，VISIBLE显示，隐藏GONE
            tv_yuangongid.setVisibility(View.GONE);//输入员工ID，VISIBLE显示，隐藏GONE
            my_qrcode.setVisibility(View.GONE);
            shoujiHaoMa.setVisibility(View.VISIBLE);

        }


        Intent intent = getIntent();
        view.setOnQRCodeReadListener(this);
        view.setQRDecodingEnabled(true);
        if (intent.getBooleanExtra(EXTRA_FORCE_FOCUS, false)) {
            view.forceAutoFocus();
        }
        view.setAutofocusInterval(intent.getIntExtra(EXTRA_FOCUS_INTERVAL, 2000));
        view.setTorchEnabled(intent.getBooleanExtra(EXTRA_TORCH_ENABLED, false));
        if (intent.getBooleanExtra(EXTRA_FRONT_CAMERA, false)) {
            view.setFrontCamera();
        }
        my_qrcode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setResult(Activity.RESULT_CANCELED, new Intent());
                finish();
                QRCodeReaderPlugin.channel.invokeMethod("onMyQrCode", "");
            }
        });
        tv_chepaifu.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setResult(Activity.RESULT_CANCELED, new Intent());
                finish();
                QRCodeReaderPlugin.channel.invokeMethod("plateNumberPay", "");
            }

        });
        tv_yuangongid.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setResult(Activity.RESULT_CANCELED, new Intent());
                finish();
                QRCodeReaderPlugin.channel.invokeMethod("staffId", "");
            }

        });
        shoujiHaoMa.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setResult(Activity.RESULT_CANCELED, new Intent());
                finish();
                QRCodeReaderPlugin.channel.invokeMethod("phone", "");
            }

        });
        Animation animation = AnimationUtils
                .loadAnimation(this, R.anim.donghua);
        scan_line.startAnimation(animation);
    }

    @Override
    public void onQRCodeRead(String text, PointF[] points) {
        if (!qrRead) {
            synchronized (this) {
                qrRead = true;
                Intent data = new Intent();
                data.putExtra(EXTRA_RESULT, text);
                setResult(Activity.RESULT_OK, data);
                finish();
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        view.startCamera();
    }

    @Override
    protected void onPause() {
        super.onPause();
        view.stopCamera();
        my_qrcode.clearAnimation();
    }

}