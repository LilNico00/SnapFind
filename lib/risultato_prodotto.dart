import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'image_matcher.dart';

final logger = Logger();

class RisultatoProdotto extends StatelessWidget {
  final Map<String, dynamic> matchResult;

  const RisultatoProdotto({super.key, required this.matchResult});

  @override
  Widget build(BuildContext context) {
    final nome = matchResult['description'] ?? 'Prodotto sconosciuto';
    final codice = matchResult['code'] ?? 'N/D';
    final prezzo = matchResult['price']?.toString() ?? '0.00';
    final stockStore = matchResult['stock_store'] ?? 0;
    final stockWarehouse = matchResult['stock_warehouse'] ?? 0;
    final imageUrl = matchResult['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dettagli prodotto"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      "❌ Immagine non disponibile",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  "📷 Nessuna immagine disponibile",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.price_check, color: Colors.green),
                      title: const Text("Prezzo"),
                      subtitle: Text("€$prezzo"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.qr_code, color: Colors.blue),
                      title: const Text("Codice"),
                      subtitle: Text(codice),
                    ),
                    ListTile(
                      leading: const Icon(Icons.store, color: Colors.orange),
                      title: const Text("In negozio"),
                      subtitle: Text("$stockStore pezzi"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.warehouse, color: Colors.brown),
                      title: const Text("In magazzino"),
                      subtitle: Text("$stockWarehouse pezzi"),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ritiraInCassa(
                    nomeProdotto: nome,
                    codiceProdotto: codice,
                    prezzo: double.tryParse(prezzo) ?? 0.0,
                  );
                  logger.i("✅ Prenotazione inviata per $nome");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Prenotazione inviata per $nome"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  logger.e("❌ Errore durante la prenotazione: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Errore durante la prenotazione"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text("Ritira in cassa"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
