import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';

final logger = Logger();

/// Indirizzo del server backend e API key
const String serverUrl = 'http://192.168.145.196:5000/match';
const String apiKey = 'SnapFind_!X9z4R7p2VbL3';

/// Inizializzazione di Firebase
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    logger.i("✅ Firebase inizializzato correttamente.");
  } catch (e) {
    logger.e("❌ Errore durante l'inizializzazione di Firebase: $e");
  }
}

/// Funzione per confrontare un'immagine con l'inventario
Future<Map<String, dynamic>?> matchImageWithInventory(File userImage) async {
  final uri = Uri.parse(serverUrl);
  final request = http.MultipartRequest('POST', uri)
    ..headers['X-API-KEY'] = apiKey
    ..files.add(await http.MultipartFile.fromPath('image', userImage.path));

  try {
    logger.i("🔄 Inizio richiesta al server per il matching dell'immagine.");
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (data.containsKey('description')) {
        logger.i("✅ Match trovato: ${data['description']}");
        return {
          'description': data['description'],
          'code': data['code'] ?? 'N/D',
          'stock_store': data['stock_store'] ?? 0,
          'stock_warehouse': data['stock_warehouse'] ?? 0,
          'price': data['price']?.toString() ?? '0.00',
          'image_url': data['image_url'] ?? '',
        };
      } else {
        logger.w("⚠️ Nessun match trovato nel risultato della risposta.");
        return null;
      }
    } else {
      final responseBody = await response.stream.bytesToString();
      logger.e("❌ Errore dal server: ${response.statusCode} - $responseBody");
      return null;
    }
  } catch (e) {
    if (e is SocketException) {
      logger.e("❌ Errore di connessione: impossibile raggiungere il server.");
    } else {
      logger.e("❌ Errore di rete: $e");
    }
    return null;
  }
}

/// Funzione per inviare una prenotazione a Firestore
Future<void> ritiraInCassa({
  required String nomeProdotto,
  required String codiceProdotto,
  required double prezzo,
}) async {
  try {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await FirebaseFirestore.instance.collection('prenotazioni').add({
      'prodotto': nomeProdotto,
      'nome': nomeProdotto,
      'codice': codiceProdotto,
      'prezzo': prezzo,
      'dataOra': timestamp,
      'stato': 'in_attesa',
    });

    logger.i("✅ Prenotazione inviata correttamente: $nomeProdotto");
  } catch (e) {
    logger.e("❌ Errore durante l'invio della prenotazione: $e");
  }
}
