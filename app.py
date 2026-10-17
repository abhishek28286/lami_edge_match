import os
import pickle
import cv2
import numpy as np
from flask import Flask, request, jsonify, redirect

app = Flask(__name__)

# Google Drive Folder IDs
LAMINATE_DRIVE_FOLDER_ID = "1q1M2-lEpIB6nNnW-A9q6T-AqQLgZ3MyK"
EDGE_DRIVE_FOLDER_ID = "1OIk4KhArNCZkFfw9L4ccBNOBZsoSmWar"

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
                print(f"Loaded {len(loaded_all_laminates)} laminates.")
    except Exception as e:
        print(f"Error loading laminates index: {e}")

    try:
        if os.path.exists('edge_swatches_index.pkl'):
            with open('edge_swatches_index.pkl', 'rb') as f:
                loaded_edge_swatches = pickle.load(f)
                print(f"Loaded {len(loaded_edge_swatches)} edge swatches.")
    except Exception as e:
        print(f"Error loading edge swatches index: {e}")

load_data()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "WoodMate Backend is Running!",
        "laminates_loaded": len(loaded_all_laminates),
        "swatches_loaded": len(loaded_edge_swatches)
    }), 200

# API to provide available brands for dropdowns in Flutter app
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

@app.route('/get_laminate_image', methods=['GET'])
def get_laminate_image():
    filename = request.args.get('filename')
    if filename:
        # Direct folder redirection or direct view link
        folder_url = f"https://drive.google.com/drive/folders/{LAMINATE_DRIVE_FOLDER_ID}"
        return redirect(folder_url, code=302)
    return "Image not found", 404

@app.route('/get_swatch_image', methods=['GET'])
def get_swatch_image():
    filename = request.args.get('filename')
    if filename:
        folder_url = f"https://drive.google.com/drive/folders/{EDGE_DRIVE_FOLDER_ID}"
        return redirect(folder_url, code=302)
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
            if lam.get('brand') == brand and lam.get('filename') == filename and lam.get('category') == category:
                lam_mean_lab = lam['mean_lab']
                break
        
        if lam_mean_lab is None:
            for lam in loaded_all_laminates:
                if lam.get('brand') == brand and lam.get('filename') == filename:
                    lam_mean_lab = lam['mean_lab']
                    break

        if lam_mean_lab is None:
            return jsonify({'error': 'Image not indexed'}), 404

        results = []
        for swatch in loaded_edge_swatches:
            if swatch.get('brand') not in selected_brands:
                continue
            if swatch.get('category') != category:
                continue

            lab_dist = np.linalg.norm(lam_mean_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 120.0))
            results.append({
                'name': swatch.get('name'),
                'filename': swatch.get('filename'),
                'brand': swatch.get('brand'),
                'category': swatch.get('category'),
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
            if swatch.get('brand') not in selected_brands:
                continue

            lab_dist = np.linalg.norm(mean_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 120.0))
            results.append({
                'name': swatch.get('name'),
                'filename': swatch.get('filename'),
                'brand': swatch.get('brand'),
                'category': swatch.get('category'),
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_uploaded: {e}")
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)