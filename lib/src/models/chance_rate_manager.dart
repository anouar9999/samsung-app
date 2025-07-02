// chance_rate_manager.dart - Create this file: lib/src/models/chance_rate_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'product_manager.dart';

class ChanceRateManager {
  // Default chance rates per product per day (0.0 to 1.0)
  static Map<String, Map<String, double>> _dailyChanceRates = {};
  static const String _prefixKey = 'chance_rates_';
  
  // Initialize default chance rates
  static Future<void> loadChanceRates() async {
    print('🎯 Loading chance rates...');
    
    // Load from SharedPreferences first, then set defaults if not found
    await _loadSavedChanceRates();
    
    // Set default rates if none exist
    if (_dailyChanceRates.isEmpty) {
      await _setDefaultChanceRates();
    }
    
    print('✅ Chance rates loaded successfully');
    debugPrintChanceRates();
  }
  
  static Future<void> _setDefaultChanceRates() async {
    print('📝 Setting default chance rates...');
    
    _dailyChanceRates = {
      '1': { // Clef USB - Medium chance
        '2025-07-02': 0.15, // 15% chance
        '2025-07-03': 0.15,
        '2025-07-04': 0.20, // Slightly higher chance
        '2025-07-05': 0.15,
        '2025-07-06': 0.10, // Lower on last day
      },
      '2': { // Produit Samsung - Low chance (premium item)
        '2025-07-02': 0.05, // 5% chance
        '2025-07-03': 0.05,
        '2025-07-04': 0.08, // Slightly higher
        '2025-07-05': 0.05,
        '2025-07-06': 0.03, // Very low on last day
      },
      '3': { // Sac à dos - Variable by availability
        '2025-07-02': 0.0,  // Not available
        '2025-07-03': 0.0,  // Not available
        '2025-07-04': 0.12, // Available with 12% chance
        '2025-07-05': 0.12,
        '2025-07-06': 0.15, // Higher chance on last day
      },
      '4': { // Porte clé - High chance (common item)
        '2025-07-02': 0.25, // 25% chance
        '2025-07-03': 0.25,
        '2025-07-04': 0.22,
        '2025-07-05': 0.20,
        '2025-07-06': 0.30, // Higher on last day
      },
      '5': { // Stickers - Very high chance (most common)
        '2025-07-02': 0.35, // 35% chance
        '2025-07-03': 0.35,
        '2025-07-04': 0.30,
        '2025-07-05': 0.32,
        '2025-07-06': 0.40, // Highest on last day
      },
      '99': { // Pas de chance - Calculated automatically
        '2025-07-02': 0.0, // Will be auto-calculated
        '2025-07-03': 0.0,
        '2025-07-04': 0.0,
        '2025-07-05': 0.0,
        '2025-07-06': 0.0,
      },
    };
    
    await _saveChanceRates();
  }
  
  static Future<void> _loadSavedChanceRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('${_prefixKey}data');
      
      if (saved != null) {
        final Map<String, dynamic> decoded = json.decode(saved);
        _dailyChanceRates = {};
        
        decoded.forEach((productId, dateMap) {
          _dailyChanceRates[productId] = {};
          (dateMap as Map<String, dynamic>).forEach((date, rate) {
            _dailyChanceRates[productId]![date] = (rate as num).toDouble();
          });
        });
        
        print('✅ Loaded saved chance rates from storage');
      }
    } catch (e) {
      print('⚠️ Error loading saved chance rates: $e');
      _dailyChanceRates = {};
    }
  }
  
  static Future<void> _saveChanceRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefixKey}data', json.encode(_dailyChanceRates));
      print('💾 Chance rates saved to storage');
    } catch (e) {
      print('❌ Error saving chance rates: $e');
    }
  }
  
  // Get chance rate for a specific product on a specific date
  static double getChanceRate(String productId, String date) {
    return _dailyChanceRates[productId]?[date] ?? 0.0;
  }
  
  // Set chance rate for a specific product on a specific date
  static Future<void> setChanceRate(String productId, String date, double rate) async {
    rate = rate.clamp(0.0, 1.0); // Ensure rate is between 0 and 1
    
    _dailyChanceRates[productId] ??= {};
    _dailyChanceRates[productId]![date] = rate;
    
    await _saveChanceRates();
    print('🎯 Set chance rate for ${ProductManager.getProductName(productId)} on $date: ${(rate * 100).toStringAsFixed(1)}%');
  }
  
  // Get chance rates for today
  static Map<String, double> getTodaysChanceRates() {
    final today = ProductManager.getCurrentDateKey();
    final todaysRates = <String, double>{};
    
    for (final productId in ['1', '2', '3', '4', '5']) {
      todaysRates[productId] = getChanceRate(productId, today);
    }
    
    return todaysRates;
  }
  
  // Calculate "Pas de chance" rate automatically
  static double calculatePasDeChanceRate(String date) {
    double totalProductRates = 0.0;
    
    for (final productId in ['1', '2', '3', '4', '5']) {
      // Only count rates for available products
      if (ProductManager.dailyQuantities[productId]?[date] != null && 
          ProductManager.dailyQuantities[productId]![date]! > 0) {
        totalProductRates += getChanceRate(productId, date);
      }
    }
    
    // "Pas de chance" gets the remaining probability
    return (1.0 - totalProductRates).clamp(0.0, 1.0);
  }
  
  // Smart product selection based on chance rates
  static String selectProductByChance(List<dynamic> availableItems) {
    final today = ProductManager.getCurrentDateKey();
    final random = Random();
    final randomValue = random.nextDouble();
    
    print('🎲 Random value: ${(randomValue * 100).toStringAsFixed(2)}%');
    
    // Build weighted selection based on chance rates
    final availableProducts = <String>[];
    final chanceRates = <double>[];
    
    for (final item in availableItems) {
      final productId = item.id.toString();
      if (productId != '99') { // Don't include "Pas de chance" in initial selection
        final chanceRate = getChanceRate(productId, today);
        if (chanceRate > 0 && ProductManager.isProductAvailable(item.id)) {
          availableProducts.add(productId);
          chanceRates.add(chanceRate);
          print('📊 ${ProductManager.getProductName(productId)}: ${(chanceRate * 100).toStringAsFixed(1)}% chance');
        }
      }
    }
    
    if (availableProducts.isEmpty) {
      print('🎯 No products available, selecting Pas de chance');
      return '99'; // Return "Pas de chance" if no products available
    }
    
    // Calculate cumulative probabilities
    double cumulativeProb = 0.0;
    final normalizedRates = <double>[];
    final totalRate = chanceRates.reduce((a, b) => a + b);
    
    print('📈 Total product rates: ${(totalRate * 100).toStringAsFixed(1)}%');
    
    for (int i = 0; i < chanceRates.length; i++) {
      cumulativeProb += (chanceRates[i] / totalRate);
      normalizedRates.add(cumulativeProb);
      print('   ${ProductManager.getProductName(availableProducts[i])}: up to ${(cumulativeProb * 100).toStringAsFixed(1)}%');
    }
    
    // Select product based on random value
    for (int i = 0; i < normalizedRates.length; i++) {
      if (randomValue <= normalizedRates[i]) {
        final selectedId = availableProducts[i];
        print('🎯 SELECTED: ${ProductManager.getProductName(selectedId)} (${(chanceRates[i] * 100).toStringAsFixed(1)}% chance)');
        return selectedId;
      }
    }
    
    // If we get here, check if we should select "Pas de chance"
    final pasDeChanceRate = calculatePasDeChanceRate(today);
    final pasDeChanceThreshold = totalRate + pasDeChanceRate;
    
    if (randomValue <= pasDeChanceThreshold) {
      print('🎯 SELECTED: Pas de chance (${(pasDeChanceRate * 100).toStringAsFixed(1)}% chance)');
      return '99';
    }
    
    // Fallback to "Pas de chance"
    print('🎯 FALLBACK: Pas de chance');
    return '99';
  }
  
  // Validate that rates don't exceed 100% for a date
  static bool validateDailyRates(String date) {
    double totalRate = 0.0;
    
    for (final productId in ['1', '2', '3', '4', '5']) {
      // Only count rates for available products
      if (ProductManager.dailyQuantities[productId]?[date] != null && 
          ProductManager.dailyQuantities[productId]![date]! > 0) {
        totalRate += getChanceRate(productId, date);
      }
    }
    
    return totalRate <= 1.0;
  }
  
  // Auto-adjust rates if they exceed 100%
  static Future<void> autoAdjustRates(String date) async {
    if (!validateDailyRates(date)) {
      print('⚠️ Total rates exceed 100% for $date, auto-adjusting...');
      
      double totalRate = 0.0;
      final availableProducts = <String>[];
      
      for (final productId in ['1', '2', '3', '4', '5']) {
        if (ProductManager.dailyQuantities[productId]?[date] != null && 
            ProductManager.dailyQuantities[productId]![date]! > 0) {
          totalRate += getChanceRate(productId, date);
          availableProducts.add(productId);
        }
      }
      
      // Normalize rates to sum to 1.0
      for (final productId in availableProducts) {
        final currentRate = getChanceRate(productId, date);
        final normalizedRate = currentRate / totalRate;
        await setChanceRate(productId, date, normalizedRate);
      }
      
      print('✅ Rates normalized for $date');
    }
  }
  
  // Get detailed statistics for a date
  static Map<String, dynamic> getDateStatistics(String date) {
    final stats = <String, dynamic>{};
    double totalProductRates = 0.0;
    int availableProducts = 0;
    
    for (final productId in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(productId);
      final chanceRate = getChanceRate(productId, date);
      final quantity = ProductManager.dailyQuantities[productId]?[date] ?? 0;
      final isAvailable = quantity > 0;
      
      stats[productName] = {
        'chanceRate': chanceRate,
        'chancePercentage': (chanceRate * 100).toStringAsFixed(1),
        'quantity': quantity,
        'isAvailable': isAvailable,
      };
      
      if (isAvailable) {
        totalProductRates += chanceRate;
        availableProducts++;
      }
    }
    
    final pasDeChanceRate = calculatePasDeChanceRate(date);
    stats['Pas de chance'] = {
      'chanceRate': pasDeChanceRate,
      'chancePercentage': (pasDeChanceRate * 100).toStringAsFixed(1),
      'quantity': 999,
      'isAvailable': true,
    };
    
    stats['_summary'] = {
      'totalProductRates': totalProductRates,
      'pasDeChanceRate': pasDeChanceRate,
      'availableProductsCount': availableProducts,
      'isValid': totalProductRates <= 1.0,
    };
    
    return stats;
  }
  
  // Debug print all chance rates
  static void debugPrintChanceRates() {
    final today = ProductManager.getCurrentDateKey();
    print('🎯 === CHANCE RATES CONFIGURATION ===');
    
    for (final date in ProductManager.getSupportedDates()) {
      print('\n📅 $date ${date == today ? "(TODAY)" : ""}:');
      
      double totalRate = 0.0;
      for (final productId in ['1', '2', '3', '4', '5']) {
        final productName = ProductManager.getProductName(productId);
        final chanceRate = getChanceRate(productId, date);
        final quantity = ProductManager.dailyQuantities[productId]?[date] ?? 0;
        
        if (quantity > 0) {
          totalRate += chanceRate;
          print('   ${productName.padRight(15)}: ${(chanceRate * 100).toStringAsFixed(1).padLeft(5)}% (${quantity} available)');
        } else {
          print('   ${productName.padRight(15)}: ${(chanceRate * 100).toStringAsFixed(1).padLeft(5)}% (NOT AVAILABLE)');
        }
      }
      
      final pasDeChanceRate = calculatePasDeChanceRate(date);
      print('   ${"Pas de chance".padRight(15)}: ${(pasDeChanceRate * 100).toStringAsFixed(1).padLeft(5)}% (auto-calculated)');
      print('   ${"TOTAL".padRight(15)}: ${((totalRate + pasDeChanceRate) * 100).toStringAsFixed(1).padLeft(5)}%');
      
      if (totalRate > 1.0) {
        print('   ⚠️  WARNING: Product rates exceed 100%!');
      }
    }
    
    print('=====================================\n');
  }
  
  // Preset configurations for easy setup
  static Future<void> applyPreset(String presetName) async {
    print('🎨 Applying preset: $presetName');
    
    switch (presetName.toLowerCase()) {
      case 'balanced':
        await _applyBalancedPreset();
        break;
      case 'generous':
        await _applyGenerousPreset();
        break;
      case 'conservative':
        await _applyConservativePreset();
        break;
      case 'premium_focused':
        await _applyPremiumFocusedPreset();
        break;
      default:
        print('❌ Unknown preset: $presetName');
        return;
    }
    
    print('✅ Applied preset: $presetName');
    debugPrintChanceRates();
  }
  
  static Future<void> _applyBalancedPreset() async {
    // Balanced chances for all products
    for (final date in ProductManager.getSupportedDates()) {
      await setChanceRate('1', date, 0.15); // USB
      await setChanceRate('2', date, 0.08); // Samsung
      await setChanceRate('3', date, date == '2025-07-02' || date == '2025-07-03' ? 0.0 : 0.12); // Backpack
      await setChanceRate('4', date, 0.25); // Keychain
      await setChanceRate('5', date, 0.35); // Stickers
    }
  }
  
  static Future<void> _applyGenerousPreset() async {
    // Higher chances for all products
    for (final date in ProductManager.getSupportedDates()) {
      await setChanceRate('1', date, 0.20); // USB
      await setChanceRate('2', date, 0.12); // Samsung
      await setChanceRate('3', date, date == '2025-07-02' || date == '2025-07-03' ? 0.0 : 0.18); // Backpack
      await setChanceRate('4', date, 0.30); // Keychain
      await setChanceRate('5', date, 0.20); // Stickers (lower to balance)
    }
  }
  
  static Future<void> _applyConservativePreset() async {
    // Lower chances, more "Pas de chance"
    for (final date in ProductManager.getSupportedDates()) {
      await setChanceRate('1', date, 0.10); // USB
      await setChanceRate('2', date, 0.05); // Samsung
      await setChanceRate('3', date, date == '2025-07-02' || date == '2025-07-03' ? 0.0 : 0.08); // Backpack
      await setChanceRate('4', date, 0.15); // Keychain
      await setChanceRate('5', date, 0.25); // Stickers
    }
  }
  
  static Future<void> _applyPremiumFocusedPreset() async {
    // Focus on premium items (USB, Samsung)
    for (final date in ProductManager.getSupportedDates()) {
      await setChanceRate('1', date, 0.25); // USB - High
      await setChanceRate('2', date, 0.15); // Samsung - High
      await setChanceRate('3', date, date == '2025-07-02' || date == '2025-07-03' ? 0.0 : 0.10); // Backpack
      await setChanceRate('4', date, 0.20); // Keychain
      await setChanceRate('5', date, 0.20); // Stickers
    }
  }
}