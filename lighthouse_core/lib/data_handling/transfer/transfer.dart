library core.data_handling.transfer;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../storage/storage.dart';
import '../../utils/utils.dart';

import 'package:markhor_testing_rig/markhor.dart';

part './http_client.dart';
part './query.dart';
part './requests.dart';
part './synchroniser.dart';

typedef JSON = Map<String, Object?>;
