import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

void main(List<String> arguments) async {
  var email = Platform.environment['EMAIL_KEY'];
  var passwd = Platform.environment['PASSWD_KEY'];
  var serverKey = Platform.environment['SERVER_KEY'];

  if (email != null && passwd != null) {
    var token = await login(email, passwd);
    var message = await checkin(token);
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

Future<String> checkin(String token) async {
  var response = await Dio(BaseOptions(
    headers: {
      'access-token': token,
    },
  )).get('https://dukouapi.com/api/user/checkin');
  return response.data.toString();
}

Future<void> sendCheckinMessage(String serverKey, String msg) async {
  await Dio().get(
    'https://sctapi.ftqq.com/$serverKey.send',
    queryParameters: {
      'title': '渡口签到结果',
      'desp': msg,
    },
  );
}
