import 'package:flutter/material.dart';

void main() {
  runApp(const AlfaDashApp());
}

class AlfaDashApp extends StatelessWidget {
  const AlfaDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfa Telemetry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- Live Telemetry Data (Αρχικοποίηση από Bluetooth) ---
  int rpm = 0;
  int speed = 0;
  double boost = 0.0;
  String gear = "N";
  bool isConnected = false;
  
  // --- Ρυθμίσεις Limiter & LED ---
  int shiftLimit = 6000;
  int ledMode = 0; // 0 = F1 Inverted, 1 = Progressive

  // Συνάρτηση για αποστολή ρυθμίσεων πίσω στο Arduino μέσω BLE
  void sendSettingsToArduino() {
    debugPrint("Sending to Arduino -> Limit: $shiftLimit, Mode: $ledMode");
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text('ALFA TELEMETRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Center(
            child: Text(
              isConnected ? 'CONNECTED  ' : 'DISCONNECTED  ',
              style: TextStyle(fontSize: 10, color: isConnected ? Colors.grey : Colors.redAccent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Το Καντράν (Auto-scaling)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: isLandscape ? 800 : 400,
                      height: isLandscape ? 400 : 560,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: isLandscape ? _buildLandscapeUI() : _buildPortraitUI(),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 2. Πάνελ Ρυθμίσεων
            _buildConfigurationPanel(isLandscape),
          ],
        ),
      ),
    );
  }

  // --- LAYOUTS ---
  Widget _buildLandscapeUI() {
    return Column(
      children: [
        _buildShiftLightsBar(32),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCard('SPEED', '$speed', 'KM/H', 56)),
              const SizedBox(width: 12),
              _buildGearBox(140, 150, 96),
              const SizedBox(width: 12),
              Expanded(child: _buildCard('RPM', '$rpm', 'REV/MIN', 48)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildBoostBar(),
      ],
    );
  }

  Widget _buildPortraitUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShiftLightsBar(24),
        _buildGearBox(160, 170, 100),
        Row(
          children: [
            Expanded(child: _buildCard('SPEED', '$speed', 'KM/H', 42)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard('TACHO', '$rpm', 'RPM', 36)),
          ],
        ),
        _buildBoostBar(),
      ],
    );
  }

  // --- Πάνελ Ρυθμίσεων ---
  Widget _buildConfigurationPanel(bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.grey.shade900, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flex(
            direction: isLandscape ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ρυθμιστής Shift Limit
              SizedBox(
                width: isLandscape ? 360 : double.infinity,
                child: Row(
                  children: [
                    const Icon(Icons.av_timer, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text('LIMITER:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: shiftLimit.toDouble(),
                        min: 3000,
                        max: 7500,
                        divisions: 45,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey.shade900,
                        onChanged: (v) {
                          setState(() {
                            shiftLimit = v.toInt();
                          });
                          sendSettingsToArduino();
                        },
                      ),
                    ),
                    Text('$shiftLimit RPM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber)),
                  ],
                ),
              ),
              if (!isLandscape) const SizedBox(height: 8),
              
              // Ρυθμιστής LED Style
              SizedBox(
                width: isLandscape ? 340 : double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.style, size: 18, color: Colors.cyanAccent),
                        SizedBox(width: 8),
                        Text('LED STYLE:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('F1 INVERTED', style: TextStyle(fontSize: 10)),
                          selected: ledMode == 0,
                          selectedColor: Colors.cyanAccent.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => ledMode = 0);
                              sendSettingsToArduino();
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('PROGRESSIVE', style: TextStyle(fontSize: 10)),
                          selected: ledMode == 1,
                          selectedColor: Colors.cyanAccent.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => ledMode = 1);
                              sendSettingsToArduino();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildShiftLightsBar(double size) {
    List<Color> colors = List.generate(8, (_) => Colors.grey.shade900);
    if (rpm >= shiftLimit && rpm > 0) {
      colors = List.generate(8, (_) => Colors.redAccent);
    } else if (rpm >= 1500) {
      int active = ((rpm - 1500) / ((shiftLimit - 1500) / 8)).clamp(0, 8).toInt();
      
      if (ledMode == 0) {
        int stage = ((rpm - 1500) / ((shiftLimit - 1500) / 4)).clamp(0, 4).toInt();
        colors[0] = Colors.green; colors[7] = Colors.green;
        if (stage >= 2) { colors[1] = Colors.green; colors[6] = Colors.green; }
        if (stage >= 3) { colors[2] = Colors.amber; colors[5] = Colors.amber; }
        if (stage >= 4) { colors[3] = Colors.red;   colors[4] = Colors.red; }
      } else {
        for (int i = 0; i < active; i++) {
          colors[i] = i < 4 ? Colors.green : (i < 6 ? Colors.amber : Colors.red);
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        8,
        (i) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[i],
            boxShadow: colors[i] != Colors.grey.shade900
                ? [BoxShadow(color: colors[i], blurRadius: 10)]
                : [],
          ),
        ),
      ),
    );
  }

  Widget _buildGearBox(double w, double h, double fontSize) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB11016), width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB11016).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      alignment: Alignment.center,
      child: Text(gear, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCard(String title, String val, String unit, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF181818), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(val, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(unit, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBoostBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF181818), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TURBO BOOST', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('${boost >= 0 ? "+" : ""}${boost.toStringAsFixed(2)} BAR', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((boost + 1.0) / 2.5).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade900,
              color: boost > 0.8 ? Colors.red : Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}
