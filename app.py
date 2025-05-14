from flask import Flask, request, jsonify
import os
import logging

app = Flask(__name__)

# Configurazione del logging
logging.basicConfig(level=logging.INFO)

# Cartella temporanea per salvare le immagini
uploads_dir = '/tmp/snapfind_uploads'
if not os.path.exists(uploads_dir):
    os.makedirs(uploads_dir)

# Endpoint per il riconoscimento dell'immagine
@app.route('/match', methods=['POST'])
def match():
    try:
        # Controlla se l'immagine è presente nella richiesta
        if 'image' not in request.files:
            app.logger.error("Nessuna immagine caricata")
            return jsonify({'error': 'No image uploaded'}), 400

        image = request.files['image']

        # Verifica se il file ha un nome valido
        if not image.filename:
            app.logger.error("Nome del file non valido")
            return jsonify({'error': 'Invalid file name'}), 400

        # Salva l'immagine nella cartella temporanea
        image_path = os.path.join(uploads_dir, image.filename)
        image.save(image_path)
        app.logger.info(f"Immagine salvata in: {image_path}")

        # Simulazione del risultato del riconoscimento
        result = {
            'description': 'Prodotto trovato',
            'code': '123456',
            'stock_store': 10,
            'stock_warehouse': 5,
            'price': 19.99,
            'image_url': 'https://example.com/product_image.png'
        }
        app.logger.info("Match trovato: Prodotto trovato")

        # Ritorna il risultato in formato JSON
        return jsonify(result), 200

    except Exception as e:
        app.logger.error(f"Errore durante il riconoscimento: {e}")
        return jsonify({'error': str(e)}), 500

# Avvia il server Flask
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
