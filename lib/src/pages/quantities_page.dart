// quantities_page.dart - Create this as a new file

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/src/models/product_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuantitiesPage extends StatefulWidget {
  @override
  _QuantitiesPageState createState() => _QuantitiesPageState();
}

class _QuantitiesPageState extends State<QuantitiesPage> {
  Map<String, Map<String, int>> _quantitiesData = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadQuantities();
    
    // Auto-refresh every 3 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadQuantities();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuantities() async {
    await ProductManager.loadDailyQuantities();
    
    final data = <String, Map<String, int>>{};
    
    for (final id in ['1', '2', '3', '4', '5']) {
      final productName = ProductManager.getProductName(id);
      final today = ProductManager.getCurrentDateKey();
      final dailyLimit = ProductManager.dailyQuantities[id]?[today] ?? 0;
      final consumed = ProductManager.consumedToday[id] ?? 0;
      final remaining = ProductManager.getRemainingQuantity(id);
      final available = ProductManager.isProductAvailable(id);
      
      data[id] = {
        'dailyLimit': dailyLimit,
        'consumed': consumed,
        'remaining': remaining,
        'available': available ? 1 : 0,
      };
    }
    
    if (mounted) {
      setState(() {
        _quantitiesData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Stock des Produits',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadQuantities,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                SizedBox(height: 20),
                _buildQuantitiesGrid(),
                SizedBox(height: 20),
                _buildSummaryCard(),
                SizedBox(height: 20),
                _buildActionsCard(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderCard() {
    final today = ProductManager.getCurrentDateKey();
    final totalProducts = _quantitiesData.length;
    final availableProducts = _quantitiesData.values
        .where((data) => data['available'] == 1)
        .length;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'État du Stock',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            today,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[300], size: 20),
              SizedBox(width: 8),
              Text(
                '$availableProducts/$totalProducts produits disponibles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitiesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail des Produits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _quantitiesData.length,
          itemBuilder: (context, index) {
            final id = _quantitiesData.keys.elementAt(index);
            return _buildProductCard(id);
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(String id) {
    final data = _quantitiesData[id]!;
    final productName = ProductManager.getProductName(id);
    final dailyLimit = data['dailyLimit']!;
    final consumed = data['consumed']!;
    final remaining = data['remaining']!;
    final isAvailable = data['available'] == 1;
    
    final percentage = dailyLimit > 0 ? (remaining / dailyLimit) : 0.0;
    
    Color cardColor;
    Color progressColor;
    IconData statusIcon;
    
    if (remaining == 0) {
      cardColor = Colors.red[50]!;
      progressColor = Colors.red[600]!;
      statusIcon = Icons.cancel;
    } else if (percentage < 0.3) {
      cardColor = Colors.orange[50]!;
      progressColor = Colors.orange[600]!;
      statusIcon = Icons.warning;
    } else {
      cardColor = Colors.green[50]!;
      progressColor = Colors.green[600]!;
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: progressColor,
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
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isAvailable ? 'Disponible' : 'Épuisé',
                      style: TextStyle(
                        fontSize: 12,
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consommé: $consumed',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Limite: $dailyLimit',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: dailyLimit > 0 ? (dailyLimit - remaining) / dailyLimit : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalLimits = _quantitiesData.values
        .map((data) => data['dailyLimit']!)
        .reduce((a, b) => a + b);
    final totalConsumed = _quantitiesData.values
        .map((data) => data['consumed']!)
        .reduce((a, b) => a + b);
    final totalRemaining = _quantitiesData.values
        .map((data) => data['remaining']!)
        .reduce((a, b) => a + b);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Résumé Global',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Limite',
                  '$totalLimits',
                  Colors.blue[600]!,
                  Icons.inventory,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Consommé',
                  '$totalConsumed',
                  Colors.orange[600]!,
                  Icons.shopping_cart,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Restant',
                  '$totalRemaining',
                  Colors.green[600]!,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[700], size: 24),
              SizedBox(width: 12),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadQuantities,
                  icon: Icon(Icons.refresh, size: 20),
                  label: Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showResetDialog,
                  icon: Icon(Icons.restore, size: 20),
                  label: Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les données se mettent à jour automatiquement toutes les 3 secondes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer le Reset'),
          content: Text(
            'Êtes-vous sûr de vouloir remettre à zéro toutes les quantités consommées aujourd\'hui?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _resetQuantities();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Reset', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetQuantities() async {
    final prefs = await SharedPreferences.getInstance();
    final today = ProductManager.getCurrentDateKey();
    
    // Clear consumed quantities
    await prefs.remove('consumed_$today');
    ProductManager.consumedToday.clear();
    
    // Reload quantities
    await _loadQuantities();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Quantités remises à zéro avec succès!'),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }
}