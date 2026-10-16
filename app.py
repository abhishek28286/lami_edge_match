import os
import numpy as np
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import pickle

app = Flask(__name__)
CORS(app)

loaded_laminates_index = {}
laminate_folders = {}
loaded_all_laminates = []
loaded_edge_swatches = []

def load_data():
    global loaded_laminates_index, laminate_folders, loaded_all_laminates, loaded_edge_swatches
    
    try:
        if os.path.exists('laminates_index.pkl'):
            with open('laminates_index.pkl', 'rb') as f:
                data = pickle.load(f)
                loaded_laminates_index = data.get('index', {})
                laminate_folders = data.get('folders', {})
                loaded_all_laminates = data.get('all_laminates', [])
    except Exception as e:
        print(f"Error loading laminates index: {e}")

    try:
        if os.path.exists('edge_swatches_index.pkl'):
            with open('edge_swatches_index.pkl', 'rb') as f:
                loaded_edge_swatches = pickle.load(f)
    except Exception as e:
        print(f"Error loading edge swatches index: {e}")

load_data()

@app.route('/get_laminate_brands', methods=['GET'])
def get_laminate_brands():
    brands = list(loaded_laminates_index.keys())
    return jsonify({'brands': brands}), 200

@app.route('/get_laminate_list', methods=['GET'])
def get_laminate_list():
    brand = request.args.get('brand')
    if brand in loaded_laminates_index:
        raw_items = loaded_laminates_index[brand].get('solid', []) + loaded_laminates_index[brand].get('texture', [])
        
        clean_items = []
        for item in raw_items:
            clean_items.append({
                'filename': item.get('filename'),
                'name': item.get('name', item.get('filename')),
                'category': item.get('category', 'solid')
            })
        return jsonify({'items': clean_items}), 200
        
    return jsonify({'items': []}), 200

@app.route('/get_laminate_image', methods=['GET'])
def get_laminate_image():
    brand = request.args.get('brand')
    category = request.args.get('category', 'solid')
    filename = request.args.get('filename')
    if brand in laminate_folders and filename:
        cats = [category, 'solid', 'texture']
        for cat in cats:
            if cat in laminate_folders[brand]:
                img_path = os.path.join(laminate_folders[brand][cat], filename)
                if os.path.exists(img_path):
                    return send_file(img_path, mimetype='image/jpeg')
    return "Image not found", 404

@app.route('/get_swatch_image', methods=['GET'])
def get_swatch_image():
    brand = request.args.get('brand')
    category = request.args.get('category', 'solid')
    filename = request.args.get('filename')
    
    for swatch in loaded_edge_swatches:
        if swatch['brand'] == brand and swatch['filename'] == filename:
            path = swatch.get('path')
            if path and os.path.exists(path):
                return send_file(path, mimetype='image/jpeg')
                
    return "Swatch image not found", 404

@app.route('/match_catalog', methods=['POST'])
def match_catalog():
    try:
        brand = request.form.get('brand')
        category = request.form.get('category', 'solid')
        filename = request.form.get('filename')
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []

        if not selected_brands or selected_brands == ['']:
            return jsonify({'error': 'Kripya kam se kam ek Edge Banding company chunein!'}), 400

        if not brand or not filename:
            return jsonify({'error': 'Invalid catalog item'}), 400

        lam_mean_lab = None
        for lam in loaded_all_laminates:
            if lam['brand'] == brand and lam['filename'] == filename and lam['category'] == category:
                lam_mean_lab = lam['mean_lab']
                break
        
        if lam_mean_lab is None:
            for lam in loaded_all_laminates:
                if lam['brand'] == brand and lam['filename'] == filename:
                    lam_mean_lab = lam['mean_lab']
                    break

        if lam_mean_lab is None:
            return jsonify({'error': 'Image not indexed'}), 404

        results = []
        for swatch in loaded_edge_swatches:
            if swatch['brand'] not in selected_brands:
                continue

            if swatch['category'] != category:
                continue

            lab_dist = np.linalg.norm(lam_mean_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 120.0))
            results.append({
                'name': swatch['name'],
                'filename': swatch['filename'],
                'brand': swatch['brand'],
                'category': swatch['category'],
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_catalog: {e}")
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
            return jsonify({'error': 'No image uploaded'}), 400

        file = request.files['image']
        img_bytes = file.read()
        
        import cv2
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
        for swatch in loaded_edge_swatches:
            if swatch['brand'] not in selected_brands:
                continue

            lab_dist = np.linalg.norm(mean_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 120.0))
            results.append({
                'name': swatch['name'],
                'filename': swatch['filename'],
                'brand': swatch['brand'],
                'category': swatch['category'],
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_uploaded: {e}")
        return jsonify({'error': str(e)}), 500

# ===== नया रूट: Laminate / Mica Matching के लिए =====
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
        
        import cv2
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
            if lam['brand'] not in selected_brands:
                continue

            lab_dist = np.linalg.norm(mean_lab - lam['mean_lab'])
            if lab_dist > 140.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 140.0))
            results.append({
                'name': lam['name'],
                'filename': lam['filename'],
                'brand': lam['brand'],
                'category': lam['category'],
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_laminate: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)