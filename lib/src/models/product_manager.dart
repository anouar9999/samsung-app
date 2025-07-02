// Updated ProductManager.dart - EXACTLY matching your Excel file

import 'package:flutter_fortune_wheel/src/models/chance_rate_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';

class ProductManager {
  static Map<String, Map<String, int>> dailyQuantities = {};
  static Map<String, int> consumedToday = {};

  static String getCurrentDateKey() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  // CORRECTED: Now exactly matches your Excel file (July 2-6, 2025)
  static Future<void> loadDailyQuantities() async {
    dailyQuantities = {
      '1': {
        // Clef USB - EXACTLY from Excel
        '2025-07-02': 5, '2025-07-03': 5, '2025-07-04': 5,
        '2025-07-05': 5, '2025-07-06': 5
      },
      '2': {
        // Produit Samsung - EXACTLY from Excel
        '2025-07-02': 2, '2025-07-03': 2, '2025-07-04': 2,
        '2025-07-05': 2, '2025-07-06': 2
      },
      '3': {
        // Sac à dos - EXACTLY from Excel
        '2025-07-02': 0, '2025-07-03': 0, '2025-07-04': 3,
        '2025-07-05': 3, '2025-07-06': 4
      },
      '4': {
        // Porte clé - EXACTLY from Excel
        '2025-07-02': 10, '2025-07-03': 10, '2025-07-04': 10,
        '2025-07-05': 10, '2025-07-06': 10
      },
      '5': {
        // Stickers - EXACTLY from Excel
        '2025-07-02': 80, '2025-07-03': 80, '2025-07-04': 80,
        '2025-07-05': 80, '2025-07-06': 80
      },
      '99': {
        // Pas de chance - always available
        '2025-07-02': 999, '2025-07-03': 999, '2025-07-04': 999,
        '2025-07-05': 999, '2025-07-06': 999
      },
    };

    await _loadConsumedQuantities();
    debugPrintTodaysQuantities();
  }

  static Future<void> _loadConsumedQuantities() async {
    final prefs = await SharedPreferences.getInstance();
    final today = getCurrentDateKey();
    final saved = prefs.getString('consumed_$today');

    if (saved != null) {
      final Map<String, dynamic> decoded = json.decode(saved);
      consumedToday = decoded.cast<String, int>();
    }
  }

  static Future<bool> _saveConsumedQuantities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = getCurrentDateKey();
      final success =
          await prefs.setString('consumed_$today', json.encode(consumedToday));

      if (success) {
        print('💾 Consumed quantities saved successfully for $today');
        return true;
      } else {
        print('❌ Failed to save consumed quantities');
        return false;
      }
    } catch (error) {
      print('❌ Exception saving consumed quantities: $error');
      return false;
    }
  }

  static bool validateQuantityIntegrity() {
    print('🔍 VALIDATING QUANTITY INTEGRITY...');
    bool isValid = true;
    final today = getCurrentDateKey();

    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = getProductName(id);
      final totalDaily = dailyQuantities[id]?[today] ?? 0;
      final consumed = consumedToday[id] ?? 0;
      final remaining = getRemainingQuantity(id);
      final expectedRemaining = totalDaily - consumed;

      print('$productName validation:');
      print('  Daily limit: $totalDaily');
      print('  Consumed: $consumed');
      print('  Remaining: $remaining');
      print('  Expected remaining: $expectedRemaining');

      if (remaining != expectedRemaining) {
        print(
            '  ❌ INTEGRITY ERROR: Remaining ($remaining) != Expected ($expectedRemaining)');
        isValid = false;
      } else if (consumed > totalDaily) {
        print(
            '  ❌ OVER-CONSUMPTION ERROR: Consumed ($consumed) > Daily limit ($totalDaily)');
        isValid = false;
      } else {
        print('  ✅ Valid');
      }
    }

    return isValid;
  }

  static void debugQuantityState(String productId, String context) {
    final today = getCurrentDateKey();
    final productName = getProductName(productId);
    final totalDaily = dailyQuantities[productId]?[today] ?? 0;
    final consumed = consumedToday[productId] ?? 0;
    final remaining = getRemainingQuantity(productId);
    final available = isProductAvailable(productId);

    print('🔧 DEBUG [$context] - $productName (ID:$productId):');
    print('   Date: $today');
    print('   Total daily limit: $totalDaily');
    print('   Consumed today: $consumed');
    print('   Remaining: $remaining');
    print('   Available: $available');
    print('   ConsumedToday map: ${consumedToday.toString()}');
    print(
        '   DailyQuantities for today: ${dailyQuantities[productId]?[today]}');
  }

  static bool isProductAvailable(dynamic productId) {
    if (productId == null) return false;

    final id = productId.toString();

    // "Pas de chance" (ID=99) is always available
    if (id == '99') return true;

    final today = getCurrentDateKey();
    final totalQuantity = dailyQuantities[id]?[today] ?? 0;
    final consumed = consumedToday[id] ?? 0;

    final available = totalQuantity > consumed;

    print(
        '🔍 Availability check for ${getProductName(id)}: $available (consumed: $consumed/$totalQuantity)');

    return available;
  }

  static bool consumeProduct(dynamic productId) {
    if (productId == null) {
      print('❌ ERROR: productId is null');
      return false;
    }

    final id = productId.toString();
    print('🔄 ATTEMPTING TO CONSUME: Product ID=$id (${getProductName(id)})');

    // Don't consume "Pas de chance" - it's unlimited
    if (id == '99') {
      print('✅ Pas de chance consumed (unlimited)');
      return true;
    }

    // Check availability BEFORE consumption
    final beforeAvailable = isProductAvailable(productId);
    final beforeQuantity = getRemainingQuantity(productId);
    final beforeConsumed = consumedToday[id] ?? 0;

    print('   Before consumption:');
    print('     Available: $beforeAvailable');
    print('     Remaining: $beforeQuantity');
    print('     Already consumed today: $beforeConsumed');

    if (beforeAvailable) {
      // CRITICAL: Increment consumed count
      consumedToday[id] = beforeConsumed + 1;

      // Save immediately to prevent data loss
      _saveConsumedQuantities().then((_) {
        print('✅ Quantities saved to SharedPreferences');
      }).catchError((error) {
        print('❌ ERROR saving quantities: $error');
      });

      // Verify the consumption worked
      final afterQuantity = getRemainingQuantity(productId);
      final afterConsumed = consumedToday[id] ?? 0;
      final afterAvailable = isProductAvailable(productId);

      print('   After consumption:');
      print('     Available: $afterAvailable');
      print('     Remaining: $afterQuantity');
      print('     Total consumed today: $afterConsumed');
      print('     Decrement successful: ${beforeQuantity > afterQuantity}');

      // VALIDATION: Check if quantity actually decremented
      if (beforeQuantity == afterQuantity) {
        print('❌ CRITICAL ERROR: Quantity did not decrement!');
        print('   Before: $beforeQuantity, After: $afterQuantity');
        print(
            '   ConsumedToday before: $beforeConsumed, after: $afterConsumed');

        // Force debug the calculation
        final today = getCurrentDateKey();
        final totalQuantity = dailyQuantities[id]?[today] ?? 0;
        print('   Debug calculation:');
        print('     Total daily limit: $totalQuantity');
        print('     Consumed count: $afterConsumed');
        print('     Expected remaining: ${totalQuantity - afterConsumed}');

        return false; // Return false to indicate the error
      }

      print(
          '✅ ${getProductName(id)} consumed successfully: $afterConsumed total consumed today');
      debugPrintTodaysQuantities();

      return true;
    } else {
      print('❌ Product not available for consumption');
      return false;
    }
  }

  static List<Fortune> getAvailableItems(List<Fortune> allItems) {
    final availableItems = <Fortune>[];

    for (var item in allItems) {
      if (item.id == null) continue;

      if (isProductAvailable(item.id)) {
        availableItems.add(item);
      }
    }

    // If no real prizes available, ensure "Pas de chance" is included
    if (availableItems.isEmpty ||
        availableItems.every((item) => item.id == 99)) {
      final pasDeChance = allItems.firstWhere(
        (item) => item.id == 99,
        orElse: () => allItems.last, // fallback
      );
      if (!availableItems.contains(pasDeChance)) {
        availableItems.add(pasDeChance);
      }
    }

    print("🎯 Available items: ${availableItems.length}");
    for (var item in availableItems) {
      print(
          "   - ${item.titleName} (ID:${item.id}) - ${getRemainingQuantity(item.id)} left");
    }

    return availableItems;
  }

  static int getRemainingQuantity(dynamic productId) {
    if (productId == null) return 0;

    final id = productId.toString();

    // "Pas de chance" has unlimited quantity
    if (id == '99') return 999;

    final today = getCurrentDateKey();
    final totalQuantity = dailyQuantities[id]?[today] ?? 0;
    final consumed = consumedToday[id] ?? 0;

    final remaining = (totalQuantity - consumed).clamp(0, totalQuantity);

    // Debug print for troubleshooting
    if (remaining < 0 || consumed > totalQuantity) {
      print('⚠️  QUANTITY CALCULATION WARNING for ${getProductName(id)}:');
      print(
          '   Total: $totalQuantity, Consumed: $consumed, Remaining: $remaining');
    }

    return remaining;
  }

  static String getProductName(String id) {
    switch (id) {
      case '1':
        return 'Clef USB';
      case '2':
        return 'Produit Samsung';
      case '3':
        return 'Sac à dos';
      case '4':
        return 'Porte clé';
      case '5':
        return 'Stickers';
      case '99':
        return 'Pas de chance';
      default:
        return 'Unknown';
    }
  }

  static void debugPrintTodaysQuantities() {
    final today = getCurrentDateKey();
    print("=== Today's Quantities ($today) ===");

    ['1', '2', '3', '4', '5', '99'].forEach((id) {
      final name = getProductName(id);
      final remaining = getRemainingQuantity(id);
      final total = dailyQuantities[id]?[today] ?? 0;
      final consumed = consumedToday[id] ?? 0;

      print("$name: $remaining/$total remaining (consumed: $consumed)");
    });

    print("===============================");
  }

  // BONUS: Add method to check if today's date is supported
  static bool isTodaySupported() {
    final today = getCurrentDateKey();
    final supportedDates = [
      '2025-07-02',
      '2025-07-03',
      '2025-07-04',
      '2025-07-05',
      '2025-07-06'
    ];
    return supportedDates.contains(today);
  }

  // BONUS: Get all supported dates
  static List<String> getSupportedDates() {
    return [
      '2025-07-02',
      '2025-07-03',
      '2025-07-04',
      '2025-07-05',
      '2025-07-06'
    ];
  }

  // BONUS: Get date-specific summary
  static Map<String, int> getDateSummary(String date) {
    final summary = <String, int>{};

    for (final id in ['1', '2', '3', '4', '5']) {
      final quantity = dailyQuantities[id]?[date] ?? 0;
      summary[getProductName(id)] = quantity;
    }

    return summary;
  }

  static Fortune selectFortuneByChance(List<Fortune> availableItems) {
    final selectedId = ChanceRateManager.selectProductByChance(availableItems);

    // Find the corresponding Fortune item
    for (final item in availableItems) {
      if (item.id.toString() == selectedId) {
        print('🎯 Selected: ${item.titleName} (ID: ${item.id})');
        return item;
      }
    }

    // Fallback to "Pas de chance"
    final fallback = availableItems.firstWhere(
      (item) => item.id == 99,
      orElse: () => availableItems.last,
    );
    print('🎯 Fallback to: ${fallback.titleName}');
    return fallback;
  }
}
