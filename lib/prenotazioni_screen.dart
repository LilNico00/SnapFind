import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrenotazioniScreen extends StatefulWidget {
  const PrenotazioniScreen({super.key});

  @override
  State<PrenotazioniScreen> createState() => _PrenotazioniScreenState();
}

class _PrenotazioniScreenState extends State<PrenotazioniScreen> {
  String filtro = 'tutte';
  String searchQuery = '';

  void _segnaComeConsegnato(String idDoc) async {
    try {
      await FirebaseFirestore.instance
          .collection('prenotazioni')
          .doc(idDoc)
          .update({'stato': 'consegnato'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Prenotazione contrassegnata come consegnata.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Errore durante l'aggiornamento dello stato: $e")),
      );
    }
  }

  void _cancellaPrenotazione(String idDoc) async {
    try {
      await FirebaseFirestore.instance
          .collection('prenotazioni')
          .doc(idDoc)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Prenotazione eliminata.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Errore durante l'eliminazione: $e")),
      );
    }
  }

  Future<void> _cancellaTutteConsegnate() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('prenotazioni')
          .where('stato', isEqualTo: 'consegnato')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Prenotazioni consegnate eliminate.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Errore durante l'eliminazione: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prenotazioni'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Elimina tutte le consegnate',
            onPressed: () async {
              final conferma = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Conferma eliminazione'),
                  content: const Text('Vuoi cancellare tutte le prenotazioni consegnate?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annulla'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Conferma'),
                    ),
                  ],
                ),
              );
              if (conferma == true) {
                await _cancellaTutteConsegnate();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cerca per nome o codice',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('prenotazioni').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final prenotazioni = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final stato = data['stato'] ?? 'in_attesa';
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  final codice = (data['codice'] ?? '').toString().toLowerCase();

                  final matchFiltro = filtro == 'tutte' || stato == filtro;
                  final matchSearch = searchQuery.isEmpty || 
                    nome.contains(searchQuery) || codice.contains(searchQuery);

                  return matchFiltro && matchSearch;
                }).toList();

                if (prenotazioni.isEmpty) {
                  return const Center(child: Text('Nessuna prenotazione trovata.'));
                }

                return ListView.builder(
                  itemCount: prenotazioni.length,
                  itemBuilder: (context, index) {
                    final doc = prenotazioni[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final stato = data['stato'] ?? 'in_attesa';

                    return ListTile(
                      title: Text(data['nome'] ?? 'Prodotto'),
                      subtitle: Text("Codice: ${data['codice'] ?? '-'}\nPrezzo: ${data['prezzo'] ?? 'N/A'}€"),
                      trailing: stato == 'consegnato'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.access_time, color: Colors.orange),
                      onTap: stato == 'in_attesa'
                          ? () => _segnaComeConsegnato(doc.id)
                          : null,
                      onLongPress: () => _cancellaPrenotazione(doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
