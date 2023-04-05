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

class TransformResult {
  int ret;
  String msg;

  TransformResult({
    required this.ret,
    required this.msg,
  });

  factory TransformResult.fromJson(Map<String, dynamic> json) =>
      TransformResult(ret: json['ret'], msg: json['msg']);
}

void main(List<String> arguments) async {
  var email = Platform.environment['EMAIL_KEY'];
  var passwd = Platform.environment['PASSWD_KEY'];
  var serverKey = Platform.environment['SERVER_KEY'];
  int trafficNum = getEnvVarAsInt('TRAFFIC_NUM');

  if (email != null &&
      passwd != null &&
      email.isNotEmpty &&
      passwd.isNotEmpty) {
    var token = await login(email, passwd);
    var checkinResult = await checkin(token);
    var message = checkinResult.result;
    if (checkinResult.ret == 1 && trafficNum > 0) {
      TransformResult transformResult = await trafficTransform(trafficNum, token);
      message += '\n${transformResult.msg}';
    }
    if (serverKey != null && serverKey.isNotEmpty) {
      await sendCheckinMessage(serverKey, message);
    }
  }
}

int getEnvVarAsInt(String envVarName) {
  final envVarValueStr = Platform.environment[envVarName];
  if (envVarValueStr == null || envVarValueStr.isEmpty) {
    return 0;
  }
  try {
    return int.parse(envVarValueStr);
  } on Exception catch (_) {
    return 0;
  }
}

Future<String> login(String email, String passwd) async {
  var response = await Dio().post(
    'https://dukou.dev/api/token',
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
  )).get('https://dukou.dev/api/user/checkin');
  print(response.data);
  return CheckinResult.fromJson(json.decode(response.data));
}

Future<TransformResult> trafficTransform(int num, String token) async {
  var response = await Dio(BaseOptions(headers: {'access-token': token})).get(
    'https://dukou.dev/api/user/koukanntraffic',
    queryParameters: {'traffic': num},
  );
  print(response.data);
  return TransformResult.fromJson(json.decode(response.data));
}

Future<void> sendCheckinMessage(String serverKey, String msg) async {
  await Dio().get(
    'https://sctapi.ftqq.com/$serverKey.send',
    queryParameters: {
      'title': 'Dukou签到结果'+'-'+msg,
      'desp': msg,
    },
  );
}
