import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'endpoints.dart';
import 'transport/interceptors/slow_request_interceptor.dart';

part 'rest_client.g.dart';

/// The CarryOn API surface. The backend has no token auth: every endpoint
/// is public and identifies the caller by a `user_id` parameter, so no
/// endpoint here carries a `RequestAuth` marker.
///
/// Responses are returned raw ([HttpResponse] with dynamic data) and
/// decoded by the mappers in `data/mappers/`; the backend's shapes are too
/// loose (ints as strings, `msg` vs `message`) for a strict generated
/// decoder.
@RestApi()
abstract class RestClient {
  factory RestClient(
    Dio dio, {
    String? baseUrl,
    ParseErrorLogger? errorLogger,
  }) = _RestClient;

  // ---------------------------------------------------------------- auth
  @POST(Endpoints.login)
  Future<HttpResponse<dynamic>> login(@Body() Map<String, dynamic> body);

  /// Runs the Shufti check on the server before answering.
  /// Ends this device's login on the server (Bearer).
  @POST(Endpoints.authLogout)
  Future<HttpResponse<dynamic>> logout();

  @POST(Endpoints.signup)
  @MultiPart()
  @Extra({slowRequestKey: true})
  Future<HttpResponse<dynamic>> signup(@Body() FormData body);

  /// Re-verification for an existing account; same slow Shufti check.
  @POST(Endpoints.identityVerify)
  @MultiPart()
  @Extra({slowRequestKey: true})
  Future<HttpResponse<dynamic>> verifyIdentity(@Body() FormData body);

  /// Opens a live Shufti session; answers with its `verification_url`.
  @POST(Endpoints.identityLive)
  Future<HttpResponse<dynamic>> startLiveIdentity(
    @Body() Map<String, dynamic> body,
  );

  /// The user after asking Shufti about a pending check.
  @GET(Endpoints.identityStatus)
  @Extra({slowRequestKey: true})
  Future<HttpResponse<dynamic>> identityStatus(@Query('user_id') int userId);

  @GET(Endpoints.userInfo)
  Future<HttpResponse<dynamic>> userInfo(@Query('id') int id);

  @POST(Endpoints.updateInfo)
  @MultiPart()
  Future<HttpResponse<dynamic>> updateInfo(
    @Query('id') int id,
    @Body() FormData body,
  );

  @DELETE(Endpoints.deleteUser)
  Future<HttpResponse<dynamic>> deleteUser(@Query('user_id') int userId);

  @POST(Endpoints.passwordResetRequest)
  Future<HttpResponse<dynamic>> requestPasswordResetCode(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.passwordResetVerify)
  Future<HttpResponse<dynamic>> verifyPasswordResetCode(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.passwordReset)
  Future<HttpResponse<dynamic>> resetPassword(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.rate)
  Future<HttpResponse<dynamic>> rate(@Body() Map<String, dynamic> body);

  // ------------------------------------------------------------- catalog
  @GET(Endpoints.services)
  Future<HttpResponse<dynamic>> services();

  @GET(Endpoints.parcelCategories)
  Future<HttpResponse<dynamic>> parcelCategories();

  @GET(Endpoints.sliders)
  Future<HttpResponse<dynamic>> sliders();

  @GET(Endpoints.sliders2)
  Future<HttpResponse<dynamic>> sliders2();

  @GET(Endpoints.texts)
  Future<HttpResponse<dynamic>> texts();

  @GET(Endpoints.appVersions)
  Future<HttpResponse<dynamic>> appVersions();

  @GET(Endpoints.weights)
  Future<HttpResponse<dynamic>> weights();

  @GET(Endpoints.tips)
  Future<HttpResponse<dynamic>> tips();

  @GET(Endpoints.appSettings)
  Future<HttpResponse<dynamic>> appSettings();

  @GET(Endpoints.stats)
  Future<HttpResponse<dynamic>> stats();

  @GET(Endpoints.countries)
  Future<HttpResponse<dynamic>> countries();

  @GET(Endpoints.citiesByCountry)
  Future<HttpResponse<dynamic>> citiesByCountry(@Path('id') int countryId);

  @GET(Endpoints.paymentMethods)
  Future<HttpResponse<dynamic>> paymentMethods();

  @POST(Endpoints.stripeCreatePayment)
  Future<HttpResponse<dynamic>> stripeCreatePayment(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.stripeSyncPayment)
  Future<HttpResponse<dynamic>> stripeSyncPayment(
    @Body() Map<String, dynamic> body,
  );

  @GET(Endpoints.parcelOrderById)
  Future<HttpResponse<dynamic>> parcelOrderById(@Query('id') int id);

  @GET(Endpoints.wallet)
  Future<HttpResponse<dynamic>> wallet(@Query('user_id') int userId);

  @GET(Endpoints.payouts)
  Future<HttpResponse<dynamic>> payouts(@Query('user_id') int userId);

  @POST(Endpoints.payouts)
  Future<HttpResponse<dynamic>> requestPayout(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.cancelPayout)
  Future<HttpResponse<dynamic>> cancelPayout(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  // ----------------------------------------------------------- addresses
  @GET(Endpoints.addresses)
  Future<HttpResponse<dynamic>> addresses(@Query('userid') int userId);

  @POST(Endpoints.createAddress)
  Future<HttpResponse<dynamic>> createAddress(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.updateAddress)
  Future<HttpResponse<dynamic>> updateAddress(
    @Query('id') int addressId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(Endpoints.deleteAddress)
  Future<HttpResponse<dynamic>> deleteAddress(
    @Query('user_id') int userId,
    @Query('address_id') int addressId,
  );

  // ------------------------------------------------------- parcel orders
  @POST(Endpoints.createParcelOrder)
  Future<HttpResponse<dynamic>> createParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.updateParcelOrder)
  Future<HttpResponse<dynamic>> updateParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.assignParcelOrder)
  Future<HttpResponse<dynamic>> assignParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.unassignParcelOrder)
  Future<HttpResponse<dynamic>> unassignParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.pickupParcelOrder)
  Future<HttpResponse<dynamic>> pickupParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.transitParcelOrder)
  Future<HttpResponse<dynamic>> transitParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.deliverParcelOrder)
  Future<HttpResponse<dynamic>> deliverParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.cancelParcelOrder)
  Future<HttpResponse<dynamic>> cancelParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.extendParcelOrder)
  Future<HttpResponse<dynamic>> extendParcelOrder(
    @Body() Map<String, dynamic> body,
  );

  @GET(Endpoints.myCreatedParcelOrders)
  Future<HttpResponse<dynamic>> myCreatedParcelOrders(
    @Query('user_id') int userId,
  );

  @GET(Endpoints.myCarriedParcelOrders)
  Future<HttpResponse<dynamic>> myCarriedParcelOrders(
    @Query('user_id') int userId,
  );

  @GET(Endpoints.unassignedParcelOrders)
  Future<HttpResponse<dynamic>> unassignedParcelOrders();

  @GET(Endpoints.matchingParcelOrders)
  Future<HttpResponse<dynamic>> matchingParcelOrders(
    @Path('carrierId') int carrierId,
  );

  @POST(Endpoints.markMatchingRead)
  Future<HttpResponse<dynamic>> markMatchingRead(
    @Path('carrierId') int carrierId,
    @Body() Map<String, dynamic> body,
  );

  // --------------------------------------------------------------- trips
  @POST(Endpoints.trips)
  Future<HttpResponse<dynamic>> createTrip(@Body() Map<String, dynamic> body);

  @PUT(Endpoints.tripById)
  Future<HttpResponse<dynamic>> updateTrip(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(Endpoints.tripById)
  Future<HttpResponse<dynamic>> deleteTrip(@Path('id') int id);

  @GET(Endpoints.tripById)
  Future<HttpResponse<dynamic>> tripById(@Path('id') int id);

  @GET(Endpoints.tripsByCarrier)
  Future<HttpResponse<dynamic>> tripsByCarrier(
    @Path('carrierId') int carrierId,
  );

  // --------------------------------------------------------- third party
  // Absolute URLs bypass the base URL; dio sends them as-is.

  @GET(Endpoints.googlePlacesAutocomplete)
  Future<HttpResponse<dynamic>> placesAutocomplete(
    @Query('input') String input,
    @Query('key') String key,
    @Query('language') String language,
  );

  @GET(Endpoints.googlePlaceDetails)
  Future<HttpResponse<dynamic>> placeDetails(
    @Query('place_id') String placeId,
    @Query('key') String key,
    @Query('language') String language,
    @Query('fields') String fields,
  );

  @GET(Endpoints.googleGeocode)
  Future<HttpResponse<dynamic>> geocode(
    @Query('latlng') String latLng,
    @Query('key') String key,
    @Query('language') String language,
  );
}
