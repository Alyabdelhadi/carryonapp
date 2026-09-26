import '../../core/base/result.dart';
import '../../domain/entities/app_texts.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/rest_client.dart';

final class CatalogRepositoryImpl extends Repository
    implements CatalogRepository {
  CatalogRepositoryImpl({
    required this.remote,
    required this.session,
    required super.crashReporter,
  });

  final RestClient remote;
  final SessionRepository session;

  @override
  Future<Result<List<AppService>, BusinessFailure>> services() {
    return asyncGuard(() async {
      final response = await remote.services();
      final items = Json.asList(response.data).map(CatalogMapper.service);
      return items.toList()..sort((a, b) => a.sortNo.compareTo(b.sortNo));
    });
  }

  @override
  Future<Result<QuickPicks, BusinessFailure>> quickPicks() {
    return asyncGuard(() async {
      final (weights, tips) = await (remote.weights(), remote.tips()).wait;
      final weightRows = Json.asList(weights.data).map(Json.asMap).toList();
      List<double> kgWhere(String flag) => [
        for (final row in weightRows)
          if (row[flag] == true || row[flag] == 1)
            if (Json.toDouble(row['kg'] ?? row['value']) case final kg?)
              if (kg > 0) kg,
      ];
      final rewards = [
        for (final row in Json.asList(tips.data).map(Json.asMap))
          if (Json.toDouble(row['amount'] ?? row['value']) case final a?)
            if (a >= 0) a,
      ];
      const fallback = QuickPicks.defaults;
      final order = kgWhere('in_order_form');
      final calculator = kgWhere('in_calculator');
      return QuickPicks(
        orderWeightsKg: order.isEmpty ? fallback.orderWeightsKg : order,
        calculatorWeightsKg: calculator.isEmpty
            ? fallback.calculatorWeightsKg
            : calculator,
        rewards: rewards.isEmpty ? fallback.rewards : rewards,
      );
    });
  }

  @override
  Future<Result<List<ParcelCategory>, BusinessFailure>> parcelCategories() {
    return asyncGuard(() async {
      final response = await remote.parcelCategories();
      final items = Json.asList(response.data)
          .map(CatalogMapper.parcelCategory);
      return items.toList()..sort((a, b) => a.sortNo.compareTo(b.sortNo));
    });
  }

  @override
  Future<Result<List<SliderImage>, BusinessFailure>> sliders() {
    return asyncGuard(() async {
      final response = await remote.sliders();
      final items = Json.asList(response.data).map(CatalogMapper.slider);
      return items.toList()..sort((a, b) => a.sortNo.compareTo(b.sortNo));
    });
  }

  @override
  Future<Result<List<SliderImage>, BusinessFailure>> secondarySliders() {
    return asyncGuard(() async {
      final response = await remote.sliders2();
      final items = Json.asList(response.data).map(CatalogMapper.slider);
      return items.toList()..sort((a, b) => a.sortNo.compareTo(b.sortNo));
    });
  }

  @override
  Future<Result<AppTexts, BusinessFailure>> texts() {
    return asyncGuard(() async {
      final response = await remote.texts();
      final texts = CatalogMapper.texts(response.data);
      if (!texts.isEmpty) await session.cacheTexts(texts);
      return texts;
    });
  }

  @override
  Future<Result<AppVersionInfo, BusinessFailure>> appVersion() {
    return asyncGuard(() async {
      final response = await remote.appVersions();
      return CatalogMapper.appVersion(Json.asMap(response.data));
    });
  }

  @override
  Future<Result<HomeStats, BusinessFailure>> homeStats() {
    return asyncGuard(() async {
      final response = await remote.stats();
      return CatalogMapper.homeStats(Json.asMap(response.data));
    });
  }

  @override
  Future<Result<AppSettings, BusinessFailure>> appSettings() {
    return asyncGuard(() async {
      final response = await remote.appSettings();
      return CatalogMapper.appSettings(Json.asMap(response.data));
    });
  }

  @override
  Future<Result<List<Country>, BusinessFailure>> countries() {
    return asyncGuard(() async {
      final response = await remote.countries();
      return Json.asList(response.data).map(CatalogMapper.country).toList();
    });
  }

  @override
  Future<Result<List<City>, BusinessFailure>> cities(int countryId) {
    return asyncGuard(() async {
      final response = await remote.citiesByCountry(countryId);
      return Json.asList(response.data).map(CatalogMapper.city).toList();
    });
  }

  @override
  Future<Result<List<PaymentMethod>, BusinessFailure>> paymentMethods() {
    return asyncGuard(() async {
      final response = await remote.paymentMethods();
      final body = Json.asMap(response.data);
      return Json.asList(body['payment_methods'])
          .map(CatalogMapper.paymentMethod)
          .toList();
    });
  }
}
