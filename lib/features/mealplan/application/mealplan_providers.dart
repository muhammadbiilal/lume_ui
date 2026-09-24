/// Meal Plan over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/mealplan_repository.dart';

final Provider<MealPlanRepository> mealPlanRepositoryProvider =
    Provider<MealPlanRepository>(
      (Ref ref) => MealPlanRepository(ref.watch(recordRepositoryProvider)),
    );
