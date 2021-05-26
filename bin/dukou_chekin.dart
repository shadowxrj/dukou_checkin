import 'dart:convert';

import 'package:dio/dio.dart';

void main(List<String> arguments) async {
  var tokenResponse = await Dio().post(
    'https://dukouapi.com/api/token',
    data: {
      'email': '1532628007@qq.com',
      'passwd': 'a19981127',
    },
  );
  var map = jsonDecode(tokenResponse.data);
  var checkinResponse = await Dio(BaseOptions(
    headers: {
      'access-token': map['token'],
    },
  )).get('https://dukouapi.com/api/user/checkin');
  print(checkinResponse.data);
}
