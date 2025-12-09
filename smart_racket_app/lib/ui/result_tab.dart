import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';

class ResultTab extends StatelessWidget {
  const ResultTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 1. Status Bar
            Container(
              color: _getStatusColor(provider.connectionStatus),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("BLE: ${provider.connectionStatus}", 
                          style: const TextStyle(color: Colors.white)),
                      if (!provider.isConnected)
                          ElevatedButton(
                              onPressed: provider.startScan, 
                              child: const Text("Scan")
                          )
                      else 
                          Text("Battery: ${provider.batteryVoltage.toStringAsFixed(2)}V",
                              style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Server: ${provider.serverStatus}", 
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (provider.serverStatus == "Failed" || provider.serverStatus == "Disconnected")
                           InkWell(
                             onTap: () => provider.updateSettings(provider.sensitivity, provider.serverIp), // Reconnect hack
                             child: const Icon(Icons.refresh, color: Colors.white, size: 16)
                           )
                    ],
                  ),
                ],
              ),
            ),

            // 2. Result Display (Big Text)
            Expanded(
              flex: 4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.lastResultType,
                        style: TextStyle(
                            fontSize: 48, 
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(provider.lastResultType))),
                    if (provider.lastResultSpeed.isNotEmpty)
                        Text(provider.lastResultSpeed,
                            style: const TextStyle(fontSize: 32, color: Colors.black87)),
                    const SizedBox(height: 16),
                    Text(provider.lastResultMessage,
                        style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status == "Connected") return Colors.green;
    if (status == "Scanning...") return Colors.orange;
    return Colors.red;
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
        case "Smash": return Colors.red;
        case "Drive": return Colors.blue;
        case "Drop": return Colors.green;
        default: return Colors.black;
    }
  }
}
