import '../../core/base/result.dart';
import '../entities/app_texts.dart';
import '../entities/catalog.dart';
import '../failures/business_failure.dart';

/// Admin-managed reference data. Read-only.
abstract interface class CatalogRepository {
  Future<Result<List<AppService>, BusinessFailure>> services();

  Future<Result<List<ParcelCategory>, BusinessFailure>> parcelCategories();

  Future<Result<List<SliderImage>, BusinessFailure>> sliders();

  Future<Result<List<SliderImage>, BusinessFailure>> secondarySliders();

  /// Fetches the UI copy and caches it for the next cold start.
  Future<Result<AppTexts, BusinessFailure>> texts();

  Future<Result<AppVersionInfo, BusinessFailure>> appVersion();

  Future<Result<AppSettings, BusinessFailure>> appSettings();

  Future<Result<HomeStats, BusinessFailure>> homeStats();

  Future<Result<List<Country>, BusinessFailure>> countries();

  Future<Result<List<City>, BusinessFailure>> cities(int countryId);

  Future<Result<List<PaymentMethod>, BusinessFailure>> paymentMethods();
}
