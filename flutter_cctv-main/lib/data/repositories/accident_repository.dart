import '/data/models/accident_dashboard_model.dart';
import '/data/services/accident_service.dart';

class AccidentRepository {
  final AccidentService _service;

  AccidentRepository({AccidentService? service})
      : _service = service ?? AccidentService();

  Future<AccidentDashboardModel?> getAccidentDashboard() async {
    try {
      final response = await _service.getAccidentDashboard();
      if (!response.succeeded || response.jsonBody == null) {
        return null;
      }

      final payload = response.jsonBody;
      if (payload is Map<String, dynamic>) {
        return AccidentDashboardModel.fromJson(payload);
      }
      if (payload is Map) {
        return AccidentDashboardModel.fromJson(
          Map<String, dynamic>.from(payload),
        );
      }
      return null;
    } catch (e) {
      print('Error loading accident dashboard: $e');
      return null;
    }
  }
}
