import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class CheckinResult {
  int ret;
  String result;

  CheckinResult({
    required this.ret,
    required this.result,
  });

  factory CheckinResult.fromJson(Map<String, dynamic> json) =>
      CheckinResult(ret: json['ret'], result: json['result']);
}

void main(List<String> arguments) async {
  var email = Platform.environment['EMAIL_KEY'];
  var passwd = Platform.environment['PASSWD_KEY'];
  var serverKey = Platform.environment['SERVER_KEY'];

  if (email != null && passwd != null) {
    var token = await login(email, passwd);
    var result = await checkin(token);
    var message = "";
    if (result.ret == 1) {
      String transformNum = await trafficTransform(result);
      if (transformNum.isNotEmpty) {
        message = '签到获得流量${transformNum}MB，转换流量成功';
      } else {
        message = "签到获得流量${transformNum}MB，转换流量失败";
      }
    } else {
      message = "不能重复签到";
    }
    if (serverKey != null) {
      await sendCheckinMessage(serverKey, message);
    }
  }
}

Future<String> login(String email, String passwd) async {
  var response = await Dio().post(
    'https://dukouapi.com/api/token',
    data: {
      'email': email,
      'passwd': passwd,
    },
  );
  var map = jsonDecode(response.data);
  return map['token'];
}

Future<CheckinResult> checkin(String token) async {
  var response = await Dio(BaseOptions(
    headers: {
      'access-token': token,
    },
  )).get('https://dukouapi.com/api/user/checkin');
  print(response.data);
  return CheckinResult.fromJson(response.data);
}

Future<String> trafficTransform(CheckinResult result) async {
  RegExp regExp = RegExp(r"\d+");
  var match = regExp.firstMatch(result.result);
  var num = match?.group(0);
  if (num != null && num.isNotEmpty) {
    var response = await Dio().get(
      'https://dukou.dev/api/user/koukanntraffic',
      queryParameters: {'traffic': num},
    );
    print(response.data);
    return num;
  }
  return "";
}

Future<void> sendCheckinMessage(String serverKey, String msg) async {
  await Dio().get(
    'https://sctapi.ftqq.com/$serverKey.send',
    queryParameters: {
      'title': 'Dukou签到结果',
      'desp': msg,
    },
  );
}
