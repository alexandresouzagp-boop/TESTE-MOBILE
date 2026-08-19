import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LedControlApp());
}

class LedControlApp extends StatelessWidget {
  const LedControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle LED ESP32',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const LedHomePage(),
    );
  }
}

class LedHomePage extends StatefulWidget {
  const LedHomePage({super.key});

  @override
  State<LedHomePage> createState() => _LedHomePageState();
}

class _LedHomePageState extends State<LedHomePage> {
  final TextEditingController ipController =
      TextEditingController(text: '192.168.4.1');
  bool ledOn = false;
  bool loading = false;
  String status = 'Desconectado';

  Future<void> setLed(bool value) async {
    final ip = ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => status = 'Informe o IP do ESP32.');
      return;
    }

    setState(() => loading = true);
    try {
      final endpoint = value ? '/led/on' : '/led/off';
      final response = await http
          .get(Uri.parse('http://$ip$endpoint'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        setState(() {
          ledOn = value;
          status = value ? 'LED ligado' : 'LED desligado';
        });
      } else {
        setState(() => status = 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() => status = 'Não foi possível conectar ao ESP32.');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> testConnection() async {
    final ip = ipController.text.trim();
    setState(() {
      loading = true;
      status = 'Testando conexão...';
    });
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 4));
      setState(() => status = response.statusCode == 200
          ? 'ESP32 conectado'
          : 'Erro HTTP ${response.statusCode}');
    } catch (_) {
      setState(() => status = 'ESP32 não encontrado');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle LED ESP32')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lightbulb_outline, size: 90),
            const SizedBox(height: 12),
            Text('Controle seu LED pelo celular',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 28),
            TextField(
              controller: ipController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'IP do ESP32',
                hintText: 'Ex.: 192.168.4.1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading ? null : testConnection,
              icon: const Icon(Icons.wifi),
              label: const Text('TESTAR CONEXÃO'),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb,
                        size: 80,
                        color: ledOn ? Colors.amber : Colors.grey),
                    const SizedBox(height: 8),
                    Text(ledOn ? 'LED LIGADO' : 'LED DESLIGADO',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loading ? null : () => setLed(true),
              icon: const Icon(Icons.power),
              label: const Text('LIGAR LED'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: loading ? null : () => setLed(false),
              icon: const Icon(Icons.power_off),
              label: const Text('DESLIGAR LED'),
            ),
            if (loading) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
