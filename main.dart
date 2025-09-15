// main.dart (versão inicial do Gigu Helper)
// Cola este arquivo em um projeto Flutter novo em lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(GiguHelperApp());
}

class GiguHelperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gigu Helper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Hotspot> hotspots = [];
  List<DeliveryRecord> records = [];
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    double hourly = _estimateHourly();

    return Scaffold(
      appBar: AppBar(title: Text('França — Gigu Helper')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Estimativa por hora'),
                subtitle: Text(hourly.isFinite ? '${currency.format(hourly)}/h' : 'Sem dados'),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _sectionTitle('Hotspots'),
                  ...hotspots.map((h) => ListTile(
                        title: Text(h.name),
                        subtitle: Text('${h.note} • médiaR\$ ${h.avgEarning.toStringAsFixed(2)}'),
                      )),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add_location),
                    label: Text('Adicionar hotspot'),
                    onPressed: () => _showAddHotspotDialog(),
                  ),
                  Divider(),
                  _sectionTitle('Registros de entregas'),
                  ...records.map((r) => ListTile(
                        title: Text('${currency.format(r.value)} — ${r.distanceKm} km'),
                        subtitle: Text('${DateFormat('dd/MM HH:mm').format(r.date)} • ${r.notes ?? ''}'),
                      )),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Adicionar entrega'),
                    onPressed: () => _showAddRecordDialog(),
                  ),
                  Divider(),
                  _sectionTitle('Agenda / Alarmes'),
                  ListTile(
                    title: Text('Entrada online 15 min antes'),
                    subtitle: Text('Configura lembrete pra entrar online antes da escala'),
                    trailing: Icon(Icons.alarm),
                    onTap: () => _showInfoDialog('Dica', 'Use o app de alarmes do celular para tocar 15 min antes da sua escala.'),
                  ),
                  Divider(),
                  _sectionTitle('Dicas rápidas'),
                  ListTile(
                    leading: Icon(Icons.star),
                    title: Text('Priorize corridas curtas com boa taxa'),
                    subtitle: Text('Evite corridas muito longas que consomem combustível'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(t, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  double _estimateHourly() {
    if (records.isEmpty) return double.nan;
    double total = records.fold(0.0, (s, r) => s + r.value);
    double totalHours = records.fold(0.0, (s, r) => s + (r.durationMinutes / 60.0));
    if (totalHours <= 0) return double.nan;
    return total / totalHours;
  }

  void _showAddHotspotDialog() {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final avgCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Novo hotspot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nome (ex: Várzea - Pizza)')),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: 'Nota/Observação')),
                  TextField(controller: avgCtrl, decoration: InputDecoration(labelText: 'Média/turno (R\$)')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        double avg = double.tryParse(avgCtrl.text.replaceAll(',', '.')) ?? 0.0;
                        hotspots.add(Hotspot(nameCtrl.text, noteCtrl.text, avg));
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Salvar'))
              ],
            ));
  }

  void _showAddRecordDialog() {
    final valueCtrl = TextEditingController();
    final distCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Adicionar entrega'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: valueCtrl, decoration: InputDecoration(labelText: 'Valor (R\$)')),
                    TextField(controller: distCtrl, decoration: InputDecoration(labelText: 'Distância (km)')),
                    TextField(controller: durCtrl, decoration: InputDecoration(labelText: 'Duração (minutos)')),
                    TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'Notas')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        double v = double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0.0;
                        double d = double.tryParse(distCtrl.text.replaceAll(',', '.')) ?? 0.0;
                        int dur = int.tryParse(durCtrl.text) ?? 10;
                        records.add(DeliveryRecord(DateTime.now(), v, d, dur, notesCtrl.text));
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Salvar'))
              ],
            ));
  }

  void _showInfoDialog(String title, String text) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))]));
  }
}

class Hotspot {
  String name;
  String note;
  double avgEarning;
  Hotspot(this.name, this.note, this.avgEarning);
}

class DeliveryRecord {
  DateTime date;
  double value;
  double distanceKm;
  int durationMinutes;
  String? notes;
  DeliveryRecord(this.date, this.value, this.distanceKm, this.durationMinutes, this.notes);
}