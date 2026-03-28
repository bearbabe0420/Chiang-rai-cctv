import '/data/services/api_manager.dart';
import '/core/config/api_config.dart';

export '/data/services/api_manager.dart' show ApiCallResponse;

class AccidentService {
  static final AccidentService _instance = AccidentService._internal();
  factory AccidentService() => _instance;
  AccidentService._internal();

  Future<ApiCallResponse> getAccidentDashboard() async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Accident Dashboard',
      apiUrl: '${ApiConfig.baseUrl}${ApiConfig.accidentsDashboardEndpoint}',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}
