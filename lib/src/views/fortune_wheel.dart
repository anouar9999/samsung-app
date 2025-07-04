import 'dart:async';
import 'dart:math';
import 'package:flutter_fortune_wheel/src/models/chance_rate_manager.dart';
import 'package:flutter_fortune_wheel/src/models/product_manager.dart';
import 'package:flutter_fortune_wheel/src/pages/quantities_page.dart';
import 'package:flutter_fortune_wheel/src/views/stress_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fortune_wheel/src/helpers/constant.dart';
import 'package:flutter_fortune_wheel/src/models/models.dart';
import 'package:flutter_fortune_wheel/src/views/arrow_view.dart';
import 'package:flutter_fortune_wheel/src/views/board_view.dart';

import '../core/core.dart';

class FortuneWheel extends StatefulWidget {
  const FortuneWheel({
    Key? key,
    required this.wheel,
    required this.onChanged,
    required this.onResult,
    this.onAnimationStart,
    this.onAnimationEnd,
  }) : super(key: key);

  ///Configure wheel
  final Wheel wheel;

  ///Handling updates of changed values while spinning
  final Function(Fortune item) onChanged;

  ///Handling returning the result of the spin
  final Function(Fortune item) onResult;

  ///Handling when starting to spin
  final VoidCallback? onAnimationStart;

  ///Handling when spinning ends
  final VoidCallback? onAnimationEnd;

  @override
  _FortuneWheelState createState() => _FortuneWheelState();
}

class _FortuneWheelState extends State<FortuneWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelAnimationController;
  late Animation _wheelAnimation;

  ///Wheel rotation angle
  ///Default value [_angle] = 0
  double _angle = 0;

  ///Current rotation angle of the wheel after spinning
  ///Default value [_currentAngle]=0
  double _currentAngle = 0;

  ///Index of the current position of the prize value on wheel
  int _currentIndex = 0;
  int? nino;

  ///Index of the result after spinning the wheel
  int _indexResult = 0;

  double get wheelSize =>
      widget.wheel.size ??
      MediaQuery.of(context as BuildContext).size.shortestSide * 0.8;
  Future<void> _initializeSpinData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    _initializeSpinData();
    _wheelAnimationController =
        AnimationController(vsync: this, duration: widget.wheel.duration);
    _wheelAnimation = CurvedAnimation(
      parent: _wheelAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
    ProductManager.loadDailyQuantities();
      ChanceRateManager.loadChanceRates();

  }

  @override
  void dispose() {
    super.dispose();
    _wheelAnimationController.dispose();
  }

  Widget _buildStressTestButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: FloatingActionButton.extended(
        onPressed:
            StressTestManager.isStressTesting ? null : _showStressTestDialog,
        backgroundColor:
            StressTestManager.isStressTesting ? Colors.grey : Colors.red[600],
        foregroundColor: Colors.white,
        heroTag: "stress_test_button",
        icon: StressTestManager.isStressTesting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.speed, size: 20),
        label: Text(
          StressTestManager.isStressTesting ? 'Testing...' : '50 Spins',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToQuantitiesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuantitiesPage()),
    );
  }

  void _showStressTestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StressTestWidget(wheelItems: widget.wheel.items);
      },
    );
  }

  Widget _buildProductsQuantityList() {
    return StatefulBuilder(
      builder: (context, setState) {
        Map<String, int> quantities = {};
        bool isLoading = true;

        // Load quantities
        Future<void> loadQuantities() async {
          await ProductManager.loadDailyQuantities();

          ['1', '2', '3', '4', '5'].forEach((id) {
            quantities[id] = ProductManager.getRemainingQuantity(id);
          });

          setState(() => isLoading = false);
        }

        // Auto-refresh every 5 seconds
        Timer.periodic(Duration(seconds: 5), (timer) {
          if (context.mounted) {
            loadQuantities();
          } else {
            timer.cancel();
          }
        });

        // Initial load
        loadQuantities();

        if (isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.blue[600], size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Produits Disponibles Aujourd\'hui',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                ProductManager.getCurrentDateKey(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              ...['1', '2', '3', '4', '5']
                  .map((id) => _buildProductRow(id, quantities)),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les quantités se remettent à zéro chaque jour',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductRow(String id, Map<String, int> quantities) {
    final quantity = quantities[id] ?? 0;
    final productName = ProductManager.getProductName(id);
    final isAvailable = quantity > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable ? Colors.green[100] : Colors.red[100],
            ),
            child: Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? Colors.green[600] : Colors.red[600],
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isAvailable ? 'Disponible' : 'Épuisé',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable ? Colors.green[600] : Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green[600] : Colors.red[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminPanel() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Panneau d\'Administration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildProductsQuantityList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWinningItemDialog(Fortune winningItem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '🎉 Congratulations! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the winning item icon if available

              SizedBox(height: 20),
              Text(
                'You won:',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                winningItem.titleName ?? 'Unknown Prize',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Text(
                  '🎊 Enjoy your prize! 🎊',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Awesome!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<int> winCountsPerPeriod = [0, 0, 0, 0];
  List<int> stocksPerPeriod = [stock1, stock2, stock3, stock4];
  bool _isStressTesting = false;
  int _currentTestSpin = 0;
  int _totalTestSpins = 200;
  Map<String, int> _testResults = {};
  List<String> _testLog = [];
  DateTime? _testStartTime;
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final meanSize = (deviceSize.width + deviceSize.height) / 2;
    final panFactor = 6 / meanSize;
    return PanAwareBuilder(
      physics: CircularPanPhysics(),
      onFling: _handleSpinByRandomPressed,
      builder: (BuildContext context, PanState panState) {
        final panAngle = panState.distance * panFactor;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _wheelAnimation,
              child: Container(
                child: BoardView(
                  items: widget.wheel.items,
                  size: wheelSize,
                ),
              ),
              builder: (context, child) {
                ///Rotation angle of the wheel
                final angle = _wheelAnimation.value * _angle;
                if (_wheelAnimationController.isAnimating) {
                  _indexResult = _getIndexFortune(angle + _currentAngle);
                  widget.onChanged.call(widget.wheel.items[_indexResult]);
                }
                final rotationAngle =
                    2 * pi * widget.wheel.rotationCount * _wheelAnimation.value;

                ///Current angle position of the standing wheel
                final current = _currentAngle + rotationAngle + panAngle;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: angle + current,
                      child: child,
                    ),
                    _buildCenterOfWheel(),
                    _buildButtonSpin(),
                  ],
                );
              },
            ),
            SizedBox(
              height: wheelSize,
              width: wheelSize,
              child: Align(
                alignment: const Alignment(1.08, 0),
                child: widget.wheel.arrowView ?? const ArrowView(),
              ),
            ),
            // _buildStressTestButton(),
                        //  _buildChanceRateButton(),  

          ],
        );
      },
    );
  }


// Widget _buildChanceRateButton() {
//   return Positioned(
//     top: 120, // Position below stress test button
//     left: 20,
//     child: FloatingActionButton(
//       mini: true,
//       backgroundColor: Colors.purple[600],
//       onPressed: _showChanceRateDialog,
//       heroTag: "chance_rate_button",
//       child: Icon(
//         Icons.tune, 
//         color: Colors.white,
//         size: 20,
//       ),
//     ),
//   );
// }
  
  
  ///UI Wheel center
  Widget _buildCenterOfWheel() {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final shortestSide = screenSize.shortestSide;

    // Calculate responsive center image size based on wheel size and screen
    double centerImageSize;

    if (shortestSide < 400) {
      // Small screens (phones in portrait)
      centerImageSize = wheelSize * 0.15; // 15% of wheel size
    } else if (shortestSide < 600) {
      // Medium screens (large phones, small tablets)
      centerImageSize = wheelSize * 0.18; // 18% of wheel size
    } else if (shortestSide < 800) {
      // Large screens (tablets)
      centerImageSize = wheelSize * 0.20; // 20% of wheel size
    } else {
      // Extra large screens (large tablets, desktops)
      centerImageSize = wheelSize * 0.22; // 22% of wheel size
    }

    // Ensure minimum and maximum sizes
    centerImageSize = centerImageSize.clamp(60.0, 180.0);

    // Add responsive padding around the center image
    final padding = centerImageSize * 0.1;

    return Container(
      width: centerImageSize + (padding * 2),
      height: centerImageSize + (padding * 2),
      child: Center(
        child: Image.asset(
          "assets/icons/go.png",
          width: centerImageSize,
          height: centerImageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildStressTestWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Test de Stress - 200 Spins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          if (!_isStressTesting) ...[
            SizedBox(height: 12),
            Text(
              'Ce test va simuler 200 spins automatiques pour vérifier que le système de quantités fonctionne correctement.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),

            // Test configuration
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuration du Test:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Nombre de spins: $_totalTestSpins'),
                  Text('• Vitesse: 10 spins/seconde'),
                  Text('• Logs détaillés: Oui'),
                  Text('• Vérification en temps réel: Oui'),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Start test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startStressTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'DÉMARRER LE TEST DE STRESS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (_isStressTesting) ...[
            SizedBox(height: 12),

            // Progress indicator
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progression:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$_currentTestSpin / $_totalTestSpins'),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _currentTestSpin / _totalTestSpins,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Temps écoulé: ${_getElapsedTime()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Real-time results
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résultats en Temps Réel:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ..._testResults.entries.map((entry) {
                    final productName =
                        ProductManager.getProductName(entry.key);
                    final wins = entry.value;
                    final remaining =
                        ProductManager.getRemainingQuantity(entry.key);

                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$productName:', style: TextStyle(fontSize: 12)),
                          Text('$wins gagnés, $remaining restants',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Stop button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _stopStressTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('ARRÊTER LE TEST'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getElapsedTime() {
    if (_testStartTime == null) return '0s';
    final elapsed = DateTime.now().difference(_testStartTime!);
    if (elapsed.inMinutes > 0) {
      return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
    }
    return '${elapsed.inSeconds}s';
  }

  Future<void> _startStressTest() async {
    print('🚀 STARTING 200 SPIN STRESS TEST');

    setState(() {
      _isStressTesting = true;
      _currentTestSpin = 0;
      _testResults.clear();
      _testLog.clear();
      _testStartTime = DateTime.now();
    });

    // Initialize test results
    for (final id in ['1', '2', '3', '4', '5', '99']) {
      _testResults[id] = 0;
    }

    // Log initial state
    _logTestState('INITIAL STATE');

    // Run 200 spins
    for (int i = 1; i <= _totalTestSpins && _isStressTesting; i++) {
      await _performStressTestSpin(i);

      // Update UI every 10 spins
      if (i % 10 == 0) {
        setState(() {
          _currentTestSpin = i;
        });

        // Small delay to allow UI updates
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    if (_isStressTesting) {
      _completeStressTest();
    }
  }

  Future<void> _performStressTestSpin(int spinNumber) async {
    // Get available items (this is your existing logic)
    final availableItems = ProductManager.getAvailableItems(widget.wheel.items);

    if (availableItems.isEmpty) {
      _testLog.add(
          'Spin $spinNumber: NO PRODUCTS AVAILABLE - Test should end here');
      print('⚠️  Spin $spinNumber: NO PRODUCTS AVAILABLE');
      return;
    }

    // Simulate random selection from available items
    final selectedItem =
        availableItems[Random().nextInt(availableItems.length)];
    final productId = selectedItem.id.toString();

    // Log before consumption
    final beforeQty = ProductManager.getRemainingQuantity(productId);
    final beforeAvailable = ProductManager.isProductAvailable(productId);

    // Try to consume the product
    final consumed = ProductManager.consumeProduct(productId);

    // Log after consumption
    final afterQty = ProductManager.getRemainingQuantity(productId);
    final afterAvailable = ProductManager.isProductAvailable(productId);

    // Record the result
    if (consumed) {
      _testResults[productId] = (_testResults[productId] ?? 0) + 1;
    }

    // Detailed logging
    final productName = ProductManager.getProductName(productId);
    final logEntry =
        'Spin $spinNumber: $productName (ID:$productId) - Before:$beforeQty/$beforeAvailable, After:$afterQty/$afterAvailable, Consumed:$consumed';
    _testLog.add(logEntry);

    print('🎯 $logEntry');

    // Validate consumption logic
    if (beforeAvailable && !consumed) {
      print('❌ ERROR: Product was available but consumption failed!');
      _testLog
          .add('ERROR in spin $spinNumber: Available product not consumed!');
    }

    if (!beforeAvailable && consumed) {
      print('❌ ERROR: Unavailable product was consumed!');
      _testLog.add('ERROR in spin $spinNumber: Unavailable product consumed!');
    }

    if (consumed && beforeQty == afterQty) {
      print('❌ ERROR: Quantity did not decrease after consumption!');
      _testLog.add('ERROR in spin $spinNumber: Quantity not decremented!');
    }
  }

  void _stopStressTest() {
    setState(() {
      _isStressTesting = false;
    });

    print('🛑 STRESS TEST STOPPED at spin $_currentTestSpin');
    _showStressTestResults();
  }

  void _completeStressTest() {
    setState(() {
      _isStressTesting = false;
      _currentTestSpin = _totalTestSpins;
    });

    print('✅ STRESS TEST COMPLETED - 200 spins finished');
    _logTestState('FINAL STATE');
    _showStressTestResults();
  }

  void _logTestState(String phase) {
    print('📊 $phase:');
    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(id);
      final remaining = ProductManager.getRemainingQuantity(id);
      final available = ProductManager.isProductAvailable(id);
      final won = _testResults[id] ?? 0;

      print(
          '   $productName: $remaining remaining, available:$available, won:$won times');
    }
  }

  void _showStressTestResults() {
    final duration = _testStartTime != null
        ? DateTime.now().difference(_testStartTime!)
        : Duration.zero;

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    '📊 Résultats du Test de Stress',
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résumé:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        'Spins effectués: $_currentTestSpin / $_totalTestSpins'),
                    Text('Durée: ${duration.inSeconds}s'),
                    Text(
                        'Vitesse: ${(_currentTestSpin / duration.inSeconds).toStringAsFixed(1)} spins/s'),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Results per product
              Text('Résultats par Produit:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              ...['1', '2', '3', '4', '5'].map((id) {
                final productName = ProductManager.getProductName(id);
                final won = _testResults[id] ?? 0;
                final remaining = ProductManager.getRemainingQuantity(id);
                final totalDaily = ProductManager.dailyQuantities[id]
                        ?[ProductManager.getCurrentDateKey()] ??
                    0;
                final consumed = totalDaily - remaining;

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
                      Text(productName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Gagné pendant le test: $won fois'),
                      Text('Limite quotidienne: $totalDaily'),
                      Text('Consommé total: $consumed'),
                      Text('Restant: $remaining'),
                      if (consumed > totalDaily)
                        Text('❌ ERREUR: Plus consommé que disponible!',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      if (consumed <= totalDaily)
                        Text('✅ Quantités correctes',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),

              SizedBox(height: 16),

              // Detailed logs
              Text('Logs Détaillés:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _testLog
                          .map((log) => Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                      fontSize: 10, fontFamily: 'monospace'),
                                ),
                              ))
                          .toList(),
                    ),
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
                        _exportTestResults();
                        Navigator.pop(context);
                      },
                      child: Text('Exporter Logs'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // _resetAllQuantities();
                        Navigator.pop(context);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Reset & Nouveau Test'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportTestResults() {
    print('📄 EXPORTING TEST RESULTS:');
    print('='.padRight(50, '='));
    print('Test Duration: ${_getElapsedTime()}');
    print('Spins Completed: $_currentTestSpin / $_totalTestSpins');
    print('');
    print('RESULTS BY PRODUCT:');

    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(id);
      final won = _testResults[id] ?? 0;
      final remaining = ProductManager.getRemainingQuantity(id);
      final totalDaily = ProductManager.dailyQuantities[id]
              ?[ProductManager.getCurrentDateKey()] ??
          0;
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

// Update your admin panel to include the stress test widget:
  ///UI Button Spin
  Widget _buildButtonSpin() {
    return Visibility(
      visible: !_wheelAnimationController.isAnimating,
      child: widget.wheel.action ??
          TextButton(
            onPressed: _handleSpinByRandomPressed,
            style: widget.wheel.spinButtonStyle ??
                TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
            child: widget.wheel.childSpinButton ??
                Text(
                  widget.wheel.titleSpinButton ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
          ),
    );
  }

  ///Handling mode random spinning
  // Future<void> _handleSpinByRandomPressed() async {
  //   if (!_wheelAnimationController.isAnimating) {
  //     //Random hệ số thập phân từ 0 đến 1
  //     double randomDouble = Random().nextDouble();
  //     //random theo số phần tử
  //     int randomLength = Random().nextInt(widget.wheel.items.length);
  //     _angle =
  //         (randomDouble + widget.wheel.rotationCount + randomLength) * 2 * pi;
  //     await Future.microtask(() => widget.onAnimationStart?.call());
  //     await _wheelAnimationController.forward(from: 0.0).then((_) {
  //       double factor = _currentAngle / (2 * pi);
  //       factor += _angle / (2 * pi);
  //       factor %= 1;
  //       _currentAngle = factor * 2 * pi;
  //       widget.onResult.call(widget.wheel.items[_indexResult]);
  //       _wheelAnimationController.reset();
  //     });
  //     await Future.microtask(() => widget.onAnimationEnd?.call());

  //     // Show popup with the winning item
  //     Fortune winningItem = widget.wheel.items[_indexResult];

  //     // Add a small delay before showing the popup for better UX
  //     await Future.delayed(Duration(milliseconds: 500));

  //     // Choose which popup style you prefer:
  //     _showWinningItemDialog(winningItem); // Simple version
  //     // OR
  //     // _showAnimatedWinningDialog(winningItem);  // Animated version
  //   }
  // }
 Future<void> _handleSpinByRandomPressed() async {
  if (!_wheelAnimationController.isAnimating) {
    // Get available items based on daily quantities
    final availableItems = ProductManager.getAvailableItems(widget.wheel.items);
    
    if (availableItems.isEmpty) {
      _showNoProductsDialog();
      return;
    }

    // 🎯 NEW: Use chance rates to select the target item
    final selectedFortune = ProductManager.selectFortuneByChance(availableItems);
    
    // Find the index of the selected item in the wheel
    int targetIndex = 0;
    for (int i = 0; i < widget.wheel.items.length; i++) {
      if (widget.wheel.items[i].id == selectedFortune.id) {
        targetIndex = i;
        break;
      }
    }

    final itemCount = widget.wheel.items.length;
    final angleFactor = _currentIndex > targetIndex
        ? _currentIndex - targetIndex
        : itemCount - (targetIndex - _currentIndex);
    _angle = (2 * pi / itemCount) * angleFactor +
        widget.wheel.rotationCount * 2 * pi;

    await Future.microtask(() => widget.onAnimationStart?.call());
    await _wheelAnimationController.forward(from: 0.0).then((_) {
      double factor = _currentAngle / (2 * pi);
      factor += _angle / (2 * pi);
      factor %= 1;
      _currentAngle = factor * 2 * pi;
      _wheelAnimationController.reset();
      _currentIndex = targetIndex;
      widget.onResult.call(widget.wheel.items[_currentIndex]);
    });
    await Future.microtask(() => widget.onAnimationEnd?.call());

    // Handle the result with quantity management
    await _handleSpinResult();
  }
}

  Future<void> _handleSpinResult() async {
    final winningItem = widget.wheel.items[_currentIndex];

    // Try to consume the product
    final consumed = ProductManager.consumeProduct(winningItem.id);

    if (consumed) {
      if (winningItem.id == 99) {
        // "Pas de chance" - losing case
        totalLosses++;

        _showLosingDialog(winningItem);
      } else {
        // Real prize won
        totalWins++;

        _showWinningDialog(winningItem);
      }
    } else {
      // Product no longer available (shouldn't happen with smart spin)
      _showProductUnavailableDialog(winningItem);
    }
  }

  void _showWinningDialog(Fortune winningItem) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated confetti or sparkles effect
                      Container(
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Multiple animated sparkles
                            ...List.generate(
                              8,
                              (index) => TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration:
                                    Duration(milliseconds: 800 + (index * 100)),
                                curve: Curves.easeOutBack,
                                builder: (context, sparkleValue, child) {
                                  final angle =
                                      (index * 45.0) * (3.14159 / 180);
                                  final radius = 40 * sparkleValue;
                                  return Positioned(
                                    top: 30 + (radius * sin(angle)),
                                    left: MediaQuery.of(context).size.width *
                                            0.4 +
                                        (radius * cos(angle)),
                                    child: Transform.rotate(
                                      angle: sparkleValue * 4,
                                      child: Icon(
                                        Icons.star,
                                        size: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main title with animated text
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, titleValue, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - titleValue)),
                            child: Opacity(
                              opacity: titleValue,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Félicitations!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Prize showcase with pulsing animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 800),
                        curve: Curves.bounceOut,
                        builder: (context, prizeValue, child) {
                          return Transform.scale(
                            scale: prizeValue,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: winningItem.backgroundColor,
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 3,
                                  ),
                                ),
                                child: winningItem.icon,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Prize details with slide animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, detailValue, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - detailValue)),
                            child: Opacity(
                              opacity: detailValue,
                              child: Column(
                                children: [
                                  Text(
                                    'Vous avez gagné',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      winningItem.titleName ?? 'Prix Mystère',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontFamily: 'SamsungSharpSans-bold',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 32),

                      // Action button with glow effect
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showLosingDialog(Fortune winningItem) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade400,
                        Colors.purple.shade500,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated sad face or consolation animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600),
                        curve: Curves.bounceOut,
                        builder: (context, emojiValue, child) {
                          return Transform.scale(
                            scale: emojiValue,
                            child: Text(
                              '💜',
                              style: TextStyle(fontSize: 48),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 16),

                      // Title with gentle animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, titleValue, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - titleValue)),
                            child: Opacity(
                              opacity: titleValue,
                              child: Text(
                                'Presque gagné!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Item with subtle animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (context, itemValue, child) {
                          return Transform.scale(
                            scale: itemValue,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: winningItem.backgroundColor
                                          ?.withOpacity(0.8) ??
                                      Colors.grey.shade300,
                                  border: Border.all(
                                    color: Colors.purple.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: winningItem.icon,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Auto-close countdown or manual close
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    // Auto-close after 3 seconds for losing dialog
    Timer(Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showNoProductsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aucun produit disponible'),
          content: Text(
              'Désolé, tous les produits d\'aujourd\'hui ont été distribués. Revenez demain!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showProductUnavailableDialog(Fortune item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Produit non disponible'),
          content: Text(
              'Ce produit n\'est plus disponible aujourd\'hui. Essayez encore!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  ///Handling the calculation of the index value of the element while spinning
  int _getIndexFortune(double value) {
    int itemCount = widget.wheel.items.length;

    double rightOffset = value - (pi / itemCount);
    return (itemCount - rightOffset / (2 * pi) * itemCount).floor() % itemCount;
  }

  ///Handling mode spinning based on prioritized winning values
  // Future<void> _handleSpinByPriorityPressed() async {
  //   if (!_wheelAnimationController.isAnimating) {
  //     int spinCount = 0;
  //     totalSpins++;

  //     final winningValues = [1, 3, 5, 7];
  //     final losingValues = [0, 2, 4, 6];
  //     List<int> targetValues = losingValues;
  //     if (isWin) {
  //       targetValues = winningValues;
  //     }

  //     final index = targetValues[Random().nextInt(targetValues.length)];
  //     spinCount++;

  //     final itemCount = widget.wheel.items.length;
  //     final angleFactor = _currentIndex > index
  //         ? _currentIndex - index
  //         : itemCount - (index - _currentIndex);
  //     _angle = (2 * pi / itemCount) * angleFactor +
  //         widget.wheel.rotationCount * 2 * pi;

  //     await Future.microtask(() => widget.onAnimationStart?.call());
  //     await _wheelAnimationController.forward(from: 0.0).then((_) {
  //       double factor = _currentAngle / (2 * pi);
  //       factor += (_angle / (2 * pi));
  //       factor %= 1;
  //       _currentAngle = factor * 2 * pi;
  //       _wheelAnimationController.reset();
  //       _currentIndex = index;
  //       widget.onResult.call(widget.wheel.items[_currentIndex]);
  //     });
  //     await Future.microtask(() => widget.onAnimationEnd?.call());

  //     print("Current index: $_currentIndex");

  //     if (winningValues.contains(_currentIndex)) {
  //       totalWins++;
  //       sendDataTrue();
  //       navigateToSecondRouteAfterDelay(true);
  //     } else {
  //       totalLosses++;
  //       controlMotor();
  //       navigateToSecondRouteAfterDelay(false);
  //     }

  //     // _saveData();
  //     Fortune _fortuneItem = widget.wheel.items[_currentIndex];
  //     _fortuneItem = _fortuneItem.copyWith(priority: 0);
  //     widget.onChanged.call(_fortuneItem);
  //   }
  // }
}
class ChanceRateQuickControl extends StatefulWidget {
  @override
  _ChanceRateQuickControlState createState() => _ChanceRateQuickControlState();
}

class _ChanceRateQuickControlState extends State<ChanceRateQuickControl> {
  Map<String, double> _todaysRates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysRates();
  }

  Future<void> _loadTodaysRates() async {
    final rates = ChanceRateManager.getTodaysChanceRates();
    setState(() {
      _todaysRates = rates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎯 Contrôle des Chances',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Column(
                  children: [
                    // Today's date
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            'Aujourd\'hui: ${ProductManager.getCurrentDateKey()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Product chance controls
                    Expanded(
                      child: ListView(
                        children: ['1', '2', '3', '4', '5'].map((id) {
                          return _buildChanceControl(id);
                        }).toList(),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Preset buttons
                    Text('Préréglages:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetButton('Équilibré', 'balanced'),
                        _buildPresetButton('Généreux', 'generous'),
                        _buildPresetButton('Conservateur', 'conservative'),
                        _buildPresetButton('Premium', 'premium_focused'),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Pas de chance calculation
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pas de chance: ${_calculatePasDeChance()}% (calculé automatiquement)',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChanceControl(String productId) {
    final productName = ProductManager.getProductName(productId);
    final currentRate = _todaysRates[productId] ?? 0.0;
    final today = ProductManager.getCurrentDateKey();
    final quantity = ProductManager.dailyQuantities[productId]?[today] ?? 0;
    final isAvailable = quantity > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                productName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                '${quantity} disponible${quantity > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: currentRate,
                  min: 0.0,
                  max: isAvailable ? 1.0 : 0.0,
                  divisions: 20,
                  label: '${(currentRate * 100).toStringAsFixed(0)}%',
                  onChanged: isAvailable ? (value) {
                    setState(() {
                      _todaysRates[productId] = value;
                    });
                    _updateChanceRate(productId, value);
                  } : null,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(currentRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, String preset) {
    return ElevatedButton(
      onPressed: () async {
        await ChanceRateManager.applyPreset(preset);
        await _loadTodaysRates();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }

  void _updateChanceRate(String productId, double rate) async {
    final today = ProductManager.getCurrentDateKey();
    await ChanceRateManager.setChanceRate(productId, today, rate);
  }

  String _calculatePasDeChance() {
    final today = ProductManager.getCurrentDateKey();
    final pasDeChanceRate = ChanceRateManager.calculatePasDeChanceRate(today);
    return (pasDeChanceRate * 100).toStringAsFixed(1);
  }
}