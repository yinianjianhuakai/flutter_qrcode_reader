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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 扫码的场景
enum QRCodeScene {
  /// 绑定加油站
  bindingGasStation,

  /// 加油
  fueling,

  /// 车牌付
  fuelingWithPlateNumberPay,

  nothing,

  /// 加油员端，用手机号码支付
  phone,
}

class QRCodeReader {
  static const MethodChannel _channel = const MethodChannel('qrcode_reader');

  int _autoFocusIntervalInMs = 5000;
  bool _forceAutoFocus = false;
  bool _torchEnabled = false;
  bool _handlePermissions = true;
  bool _executeAfterPermissionGranted = true;
  bool _frontCamera = false;

  final QRCodeScene qrCodeScene;

  ValueChanged<String> callback;

  QRCodeReader({
    this.qrCodeScene = QRCodeScene.fueling,
    this.callback,
  }) {
    _channel.setMethodCallHandler((MethodCall call) {
      if (callback != null) {
        callback(call.method);
      }
    });
  }

  QRCodeReader setAutoFocusIntervalInMs(int autoFocusIntervalInMs) {
    _autoFocusIntervalInMs = autoFocusIntervalInMs;
    return this;
  }

  QRCodeReader setForceAutoFocus(bool forceAutoFocus) {
    _forceAutoFocus = forceAutoFocus;
    return this;
  }

  QRCodeReader setTorchEnabled(bool torchEnabled) {
    _torchEnabled = torchEnabled;
    return this;
  }

  QRCodeReader setHandlePermissions(bool handlePermissions) {
    _handlePermissions = handlePermissions;
    return this;
  }

  QRCodeReader setExecuteAfterPermissionGranted(
      bool executeAfterPermissionGranted) {
    _executeAfterPermissionGranted = executeAfterPermissionGranted;
    return this;
  }

  QRCodeReader setFrontCamera(bool setFrontCamera) {
    _frontCamera = setFrontCamera;
    return this;
  }

  Future<String> scan() async {
    Map params = <String, dynamic>{
      "autoFocusIntervalInMs": _autoFocusIntervalInMs,
      "forceAutoFocus": _forceAutoFocus,
      "torchEnabled": _torchEnabled,
      "handlePermissions": _handlePermissions,
      "executeAfterPermissionGranted": _executeAfterPermissionGranted,
      "frontCamera": _frontCamera,
      "qrCodeScene": qrCodeScene.toString().split('.')[1],
    };
    if (Random().nextInt(10) < 5) {
      return await _channel.invokeMethod('readQRCode', params);
    }
    return Future.value("sddf@2dfsd23sdA");
  }
}
