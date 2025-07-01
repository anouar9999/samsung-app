// stress_test.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel/src/models/product_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StressTestManager {
  static bool _isStressTesting = false;
  static int _currentTestSpin = 0;
static int _totalTestSpins = 50;
  static Map<String, int> _testResults = {};
  static List<String> _testLog = [];
  static DateTime? _testStartTime;
  static Function(VoidCallback)? _updateUI;

  // Getters
  static bool get isStressTesting => _isStressTesting;
  static int get currentTestSpin => _currentTestSpin;
  static int get totalTestSpins => _totalTestSpins;
  static Map<String, int> get testResults => _testResults;
  static List<String> get testLog => _testLog;

  static String getElapsedTime() {
    if (_testStartTime == null) return '0s';
    final elapsed = DateTime.now().difference(_testStartTime!);
    if (elapsed.inMinutes > 0) {
      return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
    }
    return '${elapsed.inSeconds}s';
  }

  static String getSpinRate() {
    if (_testStartTime == null || _currentTestSpin == 0) return '0';
    final elapsed = DateTime.now().difference(_testStartTime!);
    final rate = _currentTestSpin / elapsed.inSeconds;
    return rate.toStringAsFixed(1);
  }

  static Future<void> startStressTest(List<Fortune> wheelItems, Function(VoidCallback) updateUI) async {
    print('🚀 STARTING 200 SPIN STRESS TEST');
    
    _updateUI = updateUI;
    _isStressTesting = true;
    _currentTestSpin = 0;
    _testResults.clear();
    _testLog.clear();
    _testStartTime = DateTime.now();
    
    updateUI(() {});
    
    // Initialize test results
    for (final id in ['1', '2', '3', '4', '5', '99']) {
      _testResults[id] = 0;
    }
    
    // Log initial state
    _logTestState('INITIAL STATE');
    
    // Run 200 spins
    for (int i = 1; i <= _totalTestSpins && _isStressTesting; i++) {
      await _performStressTestSpin(i, wheelItems);
      
      // Update UI every 5 spins
      if (i % 5 == 0) {
        _currentTestSpin = i;
        updateUI(() {});
        
        // Small delay to allow UI updates
        await Future.delayed(Duration(milliseconds: 50));
      }
    }
    
    if (_isStressTesting) {
      _completeStressTest();
    }
  }

  
static Future<void> _performStressTestSpin(int spinNumber, List<Fortune> wheelItems) async {
  // Get available items
  final availableItems = ProductManager.getAvailableItems(wheelItems);
  
  if (availableItems.isEmpty) {
    _testLog.add('Spin $spinNumber: NO PRODUCTS AVAILABLE');
    print('⚠️  Spin $spinNumber: NO PRODUCTS AVAILABLE');
    return;
  }
  
  // Simulate random selection from available items
  final selectedItem = availableItems[Random().nextInt(availableItems.length)];
  final productId = selectedItem.id.toString();
  
  // ENHANCED LOGGING: Record state before consumption
  final beforeQty = ProductManager.getRemainingQuantity(productId);
  final beforeAvailable = ProductManager.isProductAvailable(productId);
  final beforeConsumed = ProductManager.consumedToday[productId] ?? 0;
  
  print('🎯 Spin $spinNumber: Selected ${ProductManager.getProductName(productId)} (ID:$productId)');
  print('   BEFORE: Qty=$beforeQty, Available=$beforeAvailable, Consumed=$beforeConsumed');
  
  // Try to consume the product
  final consumed = ProductManager.consumeProduct(productId);
  
  // ENHANCED LOGGING: Record state after consumption
  final afterQty = ProductManager.getRemainingQuantity(productId);
  final afterAvailable = ProductManager.isProductAvailable(productId);
  final afterConsumed = ProductManager.consumedToday[productId] ?? 0;
  
  print('   AFTER:  Qty=$afterQty, Available=$afterAvailable, Consumed=$afterConsumed');
  print('   RESULT: Consumed=$consumed');
  
  // Record the result
  if (consumed) {
    _testResults[productId] = (_testResults[productId] ?? 0) + 1;
  }
  
  // CRITICAL VALIDATION CHECKS
  bool hasError = false;
  
  // Check 1: If product was available but consumption failed
  if (beforeAvailable && !consumed) {
    print('❌ ERROR: Product was available but consumption failed!');
    _testLog.add('ERROR in spin $spinNumber: Available product not consumed!');
    hasError = true;
  }
  
  // Check 2: If unavailable product was consumed
  if (!beforeAvailable && consumed) {
    print('❌ ERROR: Unavailable product was consumed!');
    _testLog.add('ERROR in spin $spinNumber: Unavailable product consumed!');
    hasError = true;
  }
  
  // Check 3: If consumed but quantity didn't decrement (CRITICAL!)
  if (consumed && productId != '99' && beforeQty == afterQty) {
    print('❌ CRITICAL ERROR: Quantity did not decrement after consumption!');
    print('   Product: ${ProductManager.getProductName(productId)}');
    print('   Before quantity: $beforeQty');
    print('   After quantity: $afterQty');
    print('   Before consumed: $beforeConsumed');
    print('   After consumed: $afterConsumed');
    
    _testLog.add('ERROR in spin $spinNumber: Quantity not decremented!');
    _testLog.add('  Product: ${ProductManager.getProductName(productId)}');
    _testLog.add('  Before: qty=$beforeQty, consumed=$beforeConsumed');
    _testLog.add('  After: qty=$afterQty, consumed=$afterConsumed');
    
    hasError = true;
  }
  
  // Check 4: If consumed count increased but quantity didn't decrease proportionally
  if (consumed && productId != '99' && (afterConsumed - beforeConsumed) != (beforeQty - afterQty)) {
    print('❌ ERROR: Consumed count and quantity decrement mismatch!');
    print('   Consumed increase: ${afterConsumed - beforeConsumed}');
    print('   Quantity decrease: ${beforeQty - afterQty}');
    
    _testLog.add('ERROR in spin $spinNumber: Consumed/quantity mismatch!');
    hasError = true;
  }
  
  // If any error detected, run integrity check
  if (hasError) {
    print('🔍 Running integrity check due to error...');
    ProductManager.validateQuantityIntegrity();
  }
  
  // Detailed logging for analysis
  final logEntry = 'Spin $spinNumber: ${ProductManager.getProductName(productId)} (ID:$productId) - Before:$beforeQty/$beforeAvailable, After:$afterQty/$afterAvailable, Consumed:$consumed';
  _testLog.add(logEntry);
}

  static void stopStressTest() {
    _isStressTesting = false;
    _updateUI?.call(() {});
    
    print('🛑 STRESS TEST STOPPED at spin $_currentTestSpin');
  }

  static void _completeStressTest() {
    _isStressTesting = false;
    _currentTestSpin = _totalTestSpins;
    _updateUI?.call(() {});
    
    print('✅ STRESS TEST COMPLETED - 200 spins finished');
    _logTestState('FINAL STATE');
  }

  static void _logTestState(String phase) {
    print('📊 $phase:');
    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(id);
      final remaining = ProductManager.getRemainingQuantity(id);
      final available = ProductManager.isProductAvailable(id);
      final won = _testResults[id] ?? 0;
      
      print('   $productName: $remaining remaining, available:$available, won:$won times');
    }
  }

  static void exportTestResults() {
    print('📄 EXPORTING TEST RESULTS:');
    print('='.padRight(50, '='));
    print('Test Duration: ${getElapsedTime()}');
    print('Spins Completed: $_currentTestSpin / $_totalTestSpins');
    print('');
    print('RESULTS BY PRODUCT:');
    
    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(id);
      final won = _testResults[id] ?? 0;
      final remaining = ProductManager.getRemainingQuantity(id);
      final totalDaily = ProductManager.dailyQuantities[id]?[ProductManager.getCurrentDateKey()] ?? 0;
      final consumed = totalDaily - remaining;
      
      print('$productName:');
      print('  Won during test: $won');
      print('  Daily limit: $totalDaily');
      print('  Total consumed: $consumed');
      print('  Remaining: $remaining');
      print('  Status: ${consumed <= totalDaily ? 'OK' : 'ERROR'}');
      print('');
    }
    
    print('DETAILED LOGS:');
    for (final log in _testLog) {
      print(log);
    }
    print('='.padRight(50, '='));
  }

  static Future<void> resetAllQuantities() async {
    final prefs = await SharedPreferences.getInstance();
    final today = ProductManager.getCurrentDateKey();
    
    // Clear consumed quantities
    await prefs.remove('consumed_$today');
    ProductManager.consumedToday.clear();
    
    print('🧪 RESET: All quantities reset for $today');
  }
}

// Stress Test UI Widget
class StressTestWidget extends StatefulWidget {
  final List<Fortune> wheelItems;

  const StressTestWidget({Key? key, required this.wheelItems}) : super(key: key);

  @override
  _StressTestWidgetState createState() => _StressTestWidgetState();
}

class _StressTestWidgetState extends State<StressTestWidget> {
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test de Stress - 200 Spins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (!StressTestManager.isStressTesting)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!StressTestManager.isStressTesting) ...[
                      _buildPreTestInfo(),
                      SizedBox(height: 16),
                      _buildCurrentQuantities(),
                      Spacer(),
                      _buildStartButton(),
                    ],
                    
                    if (StressTestManager.isStressTesting) ...[
                      _buildProgressSection(),
                      SizedBox(height: 16),
                      _buildRealTimeResults(),
                      SizedBox(height: 16),
                      _buildStopButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreTestInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'À propos du test',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('• Simule 200 spins automatiques'),
          Text('• Vitesse: ~10 spins/seconde'),
          Text('• Vérification en temps réel'),
          Text('• Logs détaillés de chaque spin'),
          Text('• Validation des quantités'),
          Text('• Rapport complet à la fin'),
        ],
      ),
    );
  }

  Widget _buildCurrentQuantities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantités Actuelles:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: ['1', '2', '3', '4', '5'].map((id) {
              final productName = ProductManager.getProductName(id);
              final remaining = ProductManager.getRemainingQuantity(id);
              final available = ProductManager.isProductAvailable(id);
              
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(productName),
                    Row(
                      children: [
                        Text('$remaining restants'),
                        SizedBox(width: 8),
                        Icon(
                          available ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: available ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startTest(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'DÉMARRER LE TEST',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${StressTestManager.currentTestSpin} / ${StressTestManager.totalTestSpins}'),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: StressTestManager.currentTestSpin / StressTestManager.totalTestSpins,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 8),
          Text(
            'Temps: ${StressTestManager.getElapsedTime()} | Vitesse: ${StressTestManager.getSpinRate()} spins/s',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeResults() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résultats en Temps Réel:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: ['1', '2', '3', '4', '5', '99'].map((id) {
                    final productName = ProductManager.getProductName(id);
                    final wins = StressTestManager.testResults[id] ?? 0;
                    final remaining = ProductManager.getRemainingQuantity(id);
                    final available = ProductManager.isProductAvailable(id);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: available ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: available ? Colors.green[200]! : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                available ? 'Disponible' : 'Épuisé',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: available ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$wins gagnés',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$remaining restants',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          StressTestManager.stopStressTest();
          _showResults();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text('ARRÊTER LE TEST'),
      ),
    );
  }

  void _startTest() async {
    await StressTestManager.startStressTest(widget.wheelItems, setState);
    
    if (StressTestManager.currentTestSpin >= StressTestManager.totalTestSpins) {
      _showResults();
    }
  }

  void _showResults() {
    Navigator.of(context).pop(); // Close test dialog
    
    showDialog(
      context: context,
      builder: (context) => StressTestResultsDialog(),
    );
  }
}

// Results Dialog
class StressTestResultsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final duration = StressTestManager.getElapsedTime();
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📊 Résultats du Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Summary
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé du Test:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Spins effectués: ${StressTestManager.currentTestSpin} / ${StressTestManager.totalTestSpins}'),
                  Text('Durée: $duration'),
                  Text('Vitesse moyenne: ${StressTestManager.getSpinRate()} spins/s'),
                  Text('Statut: ${StressTestManager.currentTestSpin >= StressTestManager.totalTestSpins ? 'TERMINÉ' : 'ARRÊTÉ'}'),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Results
            Text('Résultats Détaillés:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: ['1', '2', '3', '4', '5', '99'].map((id) {
                    final productName = ProductManager.getProductName(id);
                    final won = StressTestManager.testResults[id] ?? 0;
                    final remaining = ProductManager.getRemainingQuantity(id);
                    final totalDaily = ProductManager.dailyQuantities[id]?[ProductManager.getCurrentDateKey()] ?? 999;
                    final consumed = id == '99' ? won : totalDaily - remaining;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Gagné pendant le test: $won fois'),
                          if (id != '99') ...[
                            Text('Limite quotidienne: $totalDaily'),
                            Text('Consommé total: $consumed'),
                            Text('Restant: $remaining'),
                            if (consumed > totalDaily)
                              Text('❌ ERREUR: Plus consommé que disponible!', 
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            else
                              Text('✅ Quantités correctes', 
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ] else
                            Text('✅ Illimité (Pas de chance)', 
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      StressTestManager.exportTestResults();
                      Navigator.pop(context);
                    },
                    child: Text('Exporter Logs'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await StressTestManager.resetAllQuantities();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Reset & Nouveau Test'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}