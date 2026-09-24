import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'endpoints.dart';

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

  @POST(Endpoints.signup)
  @MultiPart()
  Future<HttpResponse<dynamic>> signup(@Body() FormData body);

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

  @POST(Endpoints.sendResetLink)
  Future<HttpResponse<dynamic>> sendResetLink(
    @Body() Map<String, dynamic> body,
  );

  @POST(Endpoints.resetPassword)
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

  @GET(Endpoints.appSettings)
  Future<HttpResponse<dynamic>> appSettings();

  @GET(Endpoints.countries)
  Future<HttpResponse<dynamic>> countries();

  @GET(Endpoints.citiesByCountry)
  Future<HttpResponse<dynamic>> citiesByCountry(@Path('id') int countryId);

  @GET(Endpoints.paymentMethods)
  Future<HttpResponse<dynamic>> paymentMethods();

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

  @POST(Endpoints.shuftiVerify)
  Future<HttpResponse<dynamic>> shuftiVerify(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

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
