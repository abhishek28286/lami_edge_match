import os
import pickle
import cv2
import numpy as np
from flask import Flask, request, jsonify, redirect, send_from_directory
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

loaded_all_laminates = []
loaded_edge_swatches = []

SUPABASE_PUBLIC_URL = "https://ehyjgdqwkfzqcktxwudn.supabase.co/storage/v1/object/public/flazzor-assets"

def load_data():
    global loaded_all_laminates, loaded_edge_swatches
    base_dir = os.path.dirname(os.path.abspath(__file__))
    lam_path = os.path.join(base_dir, 'laminates_index.pkl')
    edge_path = os.path.join(base_dir, 'edge_swatches_index.pkl')
    
    try:
        if os.path.exists(lam_path):
            with open(lam_path, 'rb') as f:
                data = pickle.load(f)
                if isinstance(data, dict):
                    loaded_all_laminates = data.get('all_laminates', [])
                elif isinstance(data, list):
                    loaded_all_laminates = data
    except Exception as e:
        print(f"Error loading laminates: {e}")

    try:
        if os.path.exists(edge_path):
            with open(edge_path, 'rb') as f:
                data = pickle.load(f)
                if isinstance(data, dict):
                    loaded_edge_swatches = data.get('all_edge_swatches', []) or data.get('edge_swatches', [])
                elif isinstance(data, list):
                    loaded_edge_swatches = data
    except Exception as e:
        print(f"Error loading edge swatches: {e}")

load_data()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "Flazzor Interior Backend is Running!",
        "laminates_loaded": len(loaded_all_laminates),
        "swatches_loaded": len(loaded_edge_swatches)
    }), 200

@app.route('/cutlist_optimizer', methods=['GET'])
def cutlist_optimizer():
    return send_from_directory('.', 'cutlist.html')

@app.route('/get_brands', methods=['GET'])
def get_brands():
    try:
        lam_brands = {str(item.get('brand')).strip() for item in loaded_all_laminates if item.get('brand')}
        edge_brands = {str(item.get('brand')).strip() for item in loaded_edge_swatches if item.get('brand')}
        return jsonify({
            'laminate_brands': sorted(list(lam_brands)),
            'edge_brands': sorted(list(edge_brands))
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_laminate_list', methods=['GET'])
def get_laminate_list():
    brand = request.args.get('brand')
    if not brand:
        return jsonify({'error': 'Brand is required'}), 400
    try:
        brand_items = []
        for item in loaded_all_laminates:
            if str(item.get('brand', '')).strip() == str(brand).strip():
                brand_items.append({
                    'filename': item.get('filename', ''),
                    'name': item.get('name', ''),
                    'brand': item.get('brand', ''),
                    'category': item.get('category', 'solid')
                })
        return jsonify({'items': brand_items}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_edge_list', methods=['GET'])
def get_edge_list():
    brand = request.args.get('brand')
    if not brand:
        return jsonify({'error': 'Brand is required'}), 400
    try:
        brand_items = []
        for item in loaded_edge_swatches:
            if str(item.get('brand', '')).strip() == str(brand).strip():
                brand_items.append({
                    'filename': item.get('filename', ''),
                    'name': item.get('name', ''),
                    'brand': item.get('brand', ''),
                    'category': item.get('category', 'solid')
                })
        return jsonify({'items': brand_items}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/laminate/<brand>/<category>/<filename>', methods=['GET'])
def get_lam_image(brand, category, filename):
    target_path = f"{brand}/{category}/{filename}" if not filename.startswith(brand) else filename
    safe_path = target_path.replace("[", "_").replace("]", "_")
    cloud_url = f"{SUPABASE_PUBLIC_URL}/laminate/{safe_path}"
    return redirect(cloud_url)

@app.route('/edge/<brand>/<category>/<filename>', methods=['GET'])
def get_edge_image(brand, category, filename):
    target_path = f"{brand}/{category}/{filename}" if not filename.startswith(brand) else filename
    safe_path = target_path.replace("[", "_").replace("]", "_")
    cloud_url = f"{SUPABASE_PUBLIC_URL}/edge/{safe_path}"
    return redirect(cloud_url)

@app.route('/match_laminate', methods=['POST'])
def match_laminate():
    try:
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []
        crop_x = float(request.form.get('crop_x', 0.5))
        crop_y = float(request.form.get('crop_y', 0.5))
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400

        file = request.files['image']
        img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            return jsonify({'error': 'Invalid image'}), 400

        h, w, _ = img.shape
        patch = img[max(0, int(crop_y*h)-30):min(h, int(crop_y*h)+30), max(0, int(crop_x*w)-30):min(w, int(crop_x*w)+30)]
        mean_lab = np.mean(cv2.cvtColor(patch, cv2.COLOR_BGR2LAB), axis=(0, 1))

        results = []
        for lam in loaded_all_laminates:
            if str(lam.get('brand', '')).strip() not in selected_brands:
                continue
            lab_dist = np.linalg.norm(mean_lab - lam['mean_lab'])
            if lab_dist > 140.0:
                continue
            results.append({
                'name': lam.get('name'),
                'filename': lam.get('filename'),
                'brand': lam.get('brand'),
                'category': lam.get('category'),
                'score': float(max(0.0, 1.0 - (lab_dist / 140.0)))
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)[:5]
        return jsonify({'matches': results}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/match', methods=['POST'])
def match_uploaded():
    try:
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []
        crop_x = float(request.form.get('crop_x', 0.5))
        crop_y = float(request.form.get('crop_y', 0.5))
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400

        file = request.files['image']
        img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            return jsonify({'error': 'Invalid image'}), 400

        h, w, _ = img.shape
        patch = img[max(0, int(crop_y*h)-30):min(h, int(crop_y*h)+30), max(0, int(crop_x*w)-30):min(w, int(crop_x*w)+30)]
        mean_lab = np.mean(cv2.cvtColor(patch, cv2.COLOR_BGR2LAB), axis=(0, 1))

        results = []
        for swatch in loaded_edge_swatches:
            if str(swatch.get('brand', '')).strip() not in selected_brands:
                continue
            lab_dist = np.linalg.norm(mean_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue
            results.append({
                'name': swatch.get('name'),
                'filename': swatch.get('filename'),
                'brand': swatch.get('brand'),
                'category': swatch.get('category'),
                'score': float(max(0.0, 1.0 - (lab_dist / 120.0)))
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)[:5]
        return jsonify({'matches': results}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)