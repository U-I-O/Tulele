// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/auth_utils.dart';
import '../models/api_trip_plan_model.dart';
import '../models/api_user_trip_model.dart'; // 确保 ApiTicket 等嵌套模型也在此或其依赖中定义

class ApiService {
  final String _baseUrl = "http://127.0.0.1:5000/api"; // 开发时用
  // final String _baseUrl = "http://localhost:5000/api"; // 或者你的实际部署地址
  // final String _baseUrl = "http://47.110.62.185:5000/api"; // 生产环境

  Future<Map<String, String>> _getHeaders() async {
    String? token = await AuthUtils.getAccessToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- TripPlan Endpoints (For templates, market discovery) ---

  /// Fetches a list of TripPlans (e.g., public templates for the market)
  Future<List<ApiTripPlan>> getMarketTripPlans({
    String? searchTerm,
    List<String>? tags,
    String? destination,
    String? sortBy, // e.g., 'rating', 'updated_at'
    int limit = 10,
    int skip = 0,
  }) async {
    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (searchTerm != null) queryParams['q'] = searchTerm;
    if (destination != null) queryParams['destination'] = destination;

    // 手动构建包含 tags 的查询字符串部分
    String tagsQueryString = "";
    if (tags != null && tags.isNotEmpty) {
      tagsQueryString = tags.map((tag) => 'tag=${Uri.encodeQueryComponent(tag)}').join('&');
    }

    // 基础 URL 和其他参数
    String baseUrlWithParams = Uri.parse('$_baseUrl/trips/plans').replace(queryParameters: queryParams).toString();
    
    // 组合最终 URL
    String finalUrl = baseUrlWithParams;
    var uri = Uri.parse(finalUrl);

    if (tagsQueryString.isNotEmpty) {
      finalUrl += (uri.hasQuery ? '&' : '?') + tagsQueryString;
    }
    
    

    final headers = await _getHeaders();
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('plans') && decodedJson['plans'] is List) {
          return (decodedJson['plans'] as List)
              .map((planJson) => ApiTripPlan.fromJson(planJson as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Expected a "plans" list in the response');
        }
      } else {
        print('Failed to load market trip plans: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load market trip plans (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching market trip plans: $e');
      throw Exception('Error fetching market trip plans: $e');
    }
  }

  /// Fetches a single TripPlan by its ID (template detail)
  Future<ApiTripPlan> getTripPlanById(String planId) async {
    final headers = await _getHeaders();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/trips/plans/$planId'), headers: headers);
      if (response.statusCode == 200) {
        // 后端直接返回 plan 对象 JSON
        return ApiTripPlan.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print('Failed to load trip plan $planId: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load trip plan (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching trip plan $planId: $e');
      throw Exception('Error fetching trip plan $planId: $e');
    }
  }
  
  /// Creates a new TripPlan
  Future<ApiTripPlan> createNewTripPlan(ApiTripPlan planData) async {
    final headers = await _getHeaders();
    try {
      final String requestBody = json.encode(planData.toJson());
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/plans'),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 201) {
        // 后端返回 {"message": "...", "plan": {...}}
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('plan')) {
          return ApiTripPlan.fromJson(decodedJson['plan'] as Map<String, dynamic>);
        } else {
          throw Exception('"plan" field missing in createNewTripPlan response');
        }
      } else {
        throw Exception('Failed to create new trip plan (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error creating new trip plan: $e');
      throw Exception('Error creating new trip plan: $e');
    }
  }

  /// Updates the core TripPlan
  Future<ApiTripPlan> updateTripPlanDetails(String planId, ApiTripPlan planData) async {
    final headers = await _getHeaders();
    try {
      final String requestBody = json.encode(planData.toJson());
      final response = await http.put(
        Uri.parse('$_baseUrl/trips/plans/$planId'),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
         // 后端返回 {"message": "...", "plan": {...}}
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('plan')) {
          return ApiTripPlan.fromJson(decodedJson['plan'] as Map<String, dynamic>);
        } else {
          throw Exception('"plan" field missing in updateTripPlanDetails response');
        }
      } else {
        throw Exception('Failed to update trip plan details (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error updating trip plan details $planId: $e');
      throw Exception('Error updating trip plan details $planId: $e');
    }
  }

  Future<bool> deleteTripPlan(String planId) async {
    final headers = await _getHeaders();
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/trips/plans/$planId'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204; // 204 No Content 也算成功
    } catch (e) {
      print('Error deleting trip plan $planId: $e');
      return false;
    }
  }


  // --- UserTrip Endpoints (For user's specific trip instances) ---

  /// Fetches UserTrips for the current user.
  Future<List<ApiUserTrip>> getUserTripsForCurrentUser({int limit = 20, int skip = 0}) async {
    String? userId = await AuthUtils.getCurrentUserId();
    if (userId == null) {
      print("User not logged in, cannot fetch user trips.");
      return []; // 或者 throw Exception("User not logged in");
    }
    Map<String, String> queryParams = {
      'user_id': userId,
      'populate_plan': 'true',
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    final uri = Uri.parse('$_baseUrl/trips/user-trips').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('trips') && decodedJson['trips'] is List) {
          return (decodedJson['trips'] as List)
              .map((tripJson) => ApiUserTrip.fromJson(tripJson as Map<String, dynamic>))
              .toList();
        } else {
           throw Exception('Expected a "trips" list in the response for user trips');
        }
      } else {
        print('Failed to load user trips for $userId: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load user trips for $userId (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching user trips for $userId: $e');
      throw Exception('Error fetching user trips for $userId: $e');
    }
  }

  /// Fetches a single UserTrip by its ID.
  Future<ApiUserTrip> getUserTripById(String userTripId, {bool populatePlan = true}) async {
    final headers = await _getHeaders();
    Map<String, String> queryParams = {
      'populate_plan': populatePlan.toString(),
    };
    final uri = Uri.parse('$_baseUrl/trips/user-trips/$userTripId').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        // 后端直接返回 user trip 对象 JSON
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        // 注意：我们后端修改后，单个对象获取是直接返回对象，而不是在 "trip" 键下
        return ApiUserTrip.fromJson(decodedJson);
      } else {
        print('Failed to load user trip $userTripId: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load user trip $userTripId (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching user trip $userTripId: $e');
      throw Exception('Error fetching user trip $userTripId: $e');
    }
  }

  /// Fetches published UserTrips for the solution market.
  Future<List<ApiUserTrip>> getPublishedUserTrips({
    String? searchTerm,
    List<String>? tags,
    String? destination,
    String? sortBy,
    int limit = 10,
    int skip = 0,
  }) async {
    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'skip': skip.toString(),
      'populate_plan': 'true',
    };
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (searchTerm != null) queryParams['q'] = searchTerm;
    if (destination != null) queryParams['destination'] = destination;

    // 手动构建包含 tags 的查询字符串部分
    String tagsQueryString = "";
    if (tags != null && tags.isNotEmpty) {
      tagsQueryString = tags.map((tag) => 'tag=${Uri.encodeQueryComponent(tag)}').join('&');
    }

    // 基础 URL 和其他参数
    String baseUrlWithParams = Uri.parse('$_baseUrl/trips/market-user-trips').replace(queryParameters: queryParams).toString();
                                                                        //  ^^^^^^^ 使用新的端点
    // 组合最终 URL
    String finalUrl = baseUrlWithParams;
    if (tagsQueryString.isNotEmpty) {
      finalUrl += (Uri.parse(baseUrlWithParams).hasQuery ? '&' : '?') + tagsQueryString;
    }

    var uri = Uri.parse(finalUrl);
    
    final headers = await _getHeaders();
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
         final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('trips') && decodedJson['trips'] is List) {
          return (decodedJson['trips'] as List)
              .map((tripJson) => ApiUserTrip.fromJson(tripJson as Map<String, dynamic>))
              .toList();
        } else {
           throw Exception('Expected a "trips" list in the response for published user trips');
        }
      } else {
        print('Failed to load published user trips: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load published user trips (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching published user trips: $e');
      throw Exception('Error fetching published user trips: $e');
    }
  }

  /// Creates a new UserTrip.
  Future<ApiUserTrip> createUserTrip(Map<String, dynamic> userTripJsonPayload) async {
    final headers = await _getHeaders();
    // 确保 creator_id 存在 (通常在调用此方法前，从 AuthUtils 获取并加入到 payload 中)
    if (userTripJsonPayload['creator_id'] == null) {
        String? userId = await AuthUtils.getCurrentUserId();
        if (userId != null) {
            userTripJsonPayload['creator_id'] = userId;
            // 也可考虑自动加入 creator_name, creator_avatar 如果 AuthUtils 能提供
        } else {
            throw Exception('Creator ID is missing and user is not logged in.');
        }
    }

    try {
      final String requestBody = json.encode(userTripJsonPayload);
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/user-trips'),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 201) {
        // 后端返回 {"message": "...", "trip": {...}}
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('trip')) {
          return ApiUserTrip.fromJson(decodedJson['trip'] as Map<String, dynamic>);
        } else {
          throw Exception('"trip" field missing in createUserTrip response');
        }
      } else {
        throw Exception('Failed to create user trip (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error creating user trip: $e');
      throw Exception('Error creating user trip: $e');
    }
  }

  /// Updates an existing UserTrip.
  Future<ApiUserTrip> updateUserTrip(String userTripId, Map<String, dynamic> userTripUpdateJsonPayload) async {
    final headers = await _getHeaders();
    try {
      final String requestBody = json.encode(userTripUpdateJsonPayload);
      final response = await http.put(
        Uri.parse('$_baseUrl/trips/user-trips/$userTripId'),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
        // 后端返回 {"message": "...", "trip": {...}}
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        if (decodedJson.containsKey('trip')) {
          return ApiUserTrip.fromJson(decodedJson['trip'] as Map<String, dynamic>);
        } else {
          throw Exception('"trip" field missing in updateUserTrip response');
        }
      } else {
        throw Exception('Failed to update user trip (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error updating user trip $userTripId: $e');
      throw Exception('Error updating user trip $userTripId: $e');
    }
  }
  
  Future<bool> deleteUserTrip(String userTripId) async {
    final headers = await _getHeaders();
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/trips/user-trips/$userTripId'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting user trip $userTripId: $e');
      return false;
    }
  }

  // --- UserTrip Sub-resource Endpoints ---
  // Example: Add ticket to UserTrip
  // (Assuming ApiTicket is defined and has toJson method)
  Future<bool> addTicketToUserTrip(String userTripId, ApiTicket ticketData) async {
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/user-trips/$userTripId/tickets'),
        headers: headers,
        body: json.encode(ticketData.toJson()), // Make sure ApiTicket has toJson()
      );
      // Backend should return 200 OK or 201 Created on success
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding ticket to $userTripId: $e');
      return false;
    }
  }

  // Example: Add member to UserTrip
  // (Assuming ApiMember is defined and has toJson method)
  Future<bool> addMemberToUserTrip(String userTripId, ApiMember memberData) async {
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/user-trips/$userTripId/members'),
        headers: headers,
        body: json.encode(memberData.toJson()), // Make sure ApiMember has toJson()
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding member to $userTripId: $e');
      return false;
    }
  }
  
  // Example: Add message to UserTrip
  // (Assuming ApiMessage is defined and has toJson method)
  Future<bool> addMessageToUserTrip(String userTripId, ApiMessage messageData) async {
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/user-trips/$userTripId/messages'),
        headers: headers,
        body: json.encode(messageData.toJson()), // Make sure ApiMessage has toJson()
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding message to $userTripId: $e');
      return false;
    }
  }
   // TODO: Add methods for notes, feeds, etc., as needed.
}