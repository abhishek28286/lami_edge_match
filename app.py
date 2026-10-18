import os
import pickle
import cv2
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

loaded_all_laminates = []
loaded_edge_swatches = []

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
                print(f"Loaded {len(loaded_all_laminates)} laminates.")
        else:
            print(f"Laminates pkl not found at {lam_path}")
    except Exception as e:
        print(f"Error loading laminates index: {e}")

    try:
        if os.path.exists(edge_path):
            with open(edge_path, 'rb') as f:
                data = pickle.load(f)
                if isinstance(data, dict):
                    loaded_edge_swatches = data.get('all_edge_swatches', []) or data.get('edge_swatches', [])
                elif isinstance(data, list):
                    loaded_edge_swatches = data
                print(f"Loaded {len(loaded_edge_swatches)} edge swatches.")
        else:
            print(f"Edge swatches pkl not found at {edge_path}")
    except Exception as e:
        print(f"Error loading edge swatches index: {e}")

# Server start hote hi data load ho jayega
load_data()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "Flazzor Interior Backend is Running!",
        "laminates_loaded": len(loaded_all_laminates),
        "swatches_loaded": len(loaded_edge_swatches)
    }), 200

@app.route('/get_brands', methods=['GET'])
def get_brands():
    try:
        lam_brands = list(set([item['brand'] for item in loaded_all_laminates if 'brand' in item]))
        edge_brands = list(set([item['brand'] for item in loaded_edge_swatches if 'brand' in item]))
        return jsonify({
            'laminate_brands': sorted(lam_brands),
            'edge_brands': sorted(edge_brands)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_laminate_list', methods=['GET'])
def get_laminate_list():
    brand = request.args.get('brand')
    if not brand:
        return jsonify({'error': 'Brand is required'}), 400
    try:
        brand_items = [
            {
                'filename': item.get('filename'),
                'name': item.get('name'),
                'brand': item.get('brand'),
                'category': item.get('category', 'solid')
            }
            for item in loaded_all_laminates 
            if item.get('brand') == brand
        ]
        return jsonify({'items': brand_items}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/match_laminate', methods=['POST'])
def match_laminate():
    try:
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []
        
        if not selected_brands or selected_brands == ['']:
            return jsonify({'error': 'Kripya kam se kam ek Laminate company chunein!'}), 400

        crop_x = float(request.form.get('crop_x', 0.5))
        crop_y = float(request.form.get('crop_y', 0.5))
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400

        file = request.files['image']
        img_bytes = file.read()
        
        nparr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return jsonify({'error': 'Invalid image format'}), 400

        h, w, _ = img.shape
        cx = int(crop_x * w)
        cy = int(crop_y * h)
        
        box_size = 30
        x1 = max(0, cx - box_size)
        y1 = max(0, cy - box_size)
        x2 = min(w, cx + box_size)
        y2 = min(h, cy + box_size)
        
        patch = img[y1:y2, x1:x2]
        patch_lab = cv2.cvtColor(patch, cv2.COLOR_BGR2LAB)
        mean_lab = np.mean(patch_lab, axis=(0, 1))

        results = []
        for lam in loaded_all_laminates:
            if lam.get('brand') not in selected_brands:
                continue

            lab_dist = np.linalg.norm(mean_lab - lam['mean_lab'])
            if lab_dist > 140.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 140.0))
            results.append({
                'name': lam.get('name'),
                'filename': lam.get('filename'),
                'brand': lam.get('brand'),
                'category': lam.get('category'),
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_laminate: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/match', methods=['POST'])
def match_uploaded():
    try:
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []
        
        if not selected_brands or selected_brands == ['']:
            return jsonify({'error': 'Kripya kam se kam ek Edge Banding company chunein!'}), 400

        crop_x = float(request.form.get('crop_x', 0.5))
        crop_y = float(request.form.get('crop_y', 0.5))
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image