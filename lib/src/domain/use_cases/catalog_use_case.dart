import '../../core/base/result.dart';
import '../entities/app_texts.dart';
import '../entities/catalog.dart';
import '../failures/business_failure.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/session_repository.dart';

final class GetServicesUseCase {
  GetServicesUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<AppService>, BusinessFailure>> call() =>
      catalog.services();
}

final class GetParcelCategoriesUseCase {
  GetParcelCategoriesUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<ParcelCategory>, BusinessFailure>> call() =>
      catalog.parcelCategories();
}

final class GetSlidersUseCase {
  GetSlidersUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<SliderImage>, BusinessFailure>> call({
    bool secondary = false,
  }) {
    return secondary ? catalog.secondarySliders() : catalog.sliders();
  }
}

/// Server copy with the cached copy as the offline fallback.
final class GetAppTextsUseCase {
  GetAppTextsUseCase(this.catalog, this.session);

  final CatalogRepository catalog;
  final SessionRepository session;

  AppTexts get cached => session.cachedTexts;

  Future<AppTexts> call() async {
    final result = await catalog.texts();
    return switch (result) {
      Success(:final data) when !data.isEmpty => data,
      _ => session.cachedTexts,
    };
  }
}

final class GetHomeStatsUseCase {
  GetHomeStatsUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<HomeStats, BusinessFailure>> call() => catalog.homeStats();
}

final class GetAppVersionUseCase {
  GetAppVersionUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<AppVersionInfo, BusinessFailure>> call() =>
      catalog.appVersion();
}

final class GetCountriesUseCase {
  GetCountriesUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<Country>, BusinessFailure>> call() => catalog.countries();
}

final class GetCitiesUseCase {
  GetCitiesUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<City>, BusinessFailure>> call(int countryId) =>
      catalog.cities(countryId);
}

final class GetPaymentMethodsUseCase {
  GetPaymentMethodsUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<List<PaymentMethod>, BusinessFailure>> call() =>
      catalog.paymentMethods();
}

final class GetQuickPicksUseCase {
  GetQuickPicksUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<QuickPicks, BusinessFailure>> call() => catalog.quickPicks();
}

final class GetAppSettingsUseCase {
  GetAppSettingsUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<Result<AppSettings, BusinessFailure>> call() => catalog.appSettings();
}
