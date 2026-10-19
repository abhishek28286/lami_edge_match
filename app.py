import os
import pickle
import cv2
import numpy as np
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

loaded_all_laminates = []
loaded_edge_swatches = []
loaded_laminate_gdrive = {}
loaded_edge_gdrive = {}

def load_data():
    global loaded_all_laminates, loaded_edge_swatches, loaded_laminate_gdrive, loaded_edge_gdrive
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    lam_path = os.path.join(base_dir, 'laminates_index.pkl')
    edge_path = os.path.join(base_dir, 'edge_swatches_index.pkl')
    lam_gdrive_path = os.path.join(base_dir, 'laminates_gdrive_index.pkl')
    edge_gdrive_path = os.path.join(base_dir, 'edge_gdrive_index.pkl')
    
    try:
        if os.path.exists(lam_path):
            with open(lam_path, 'rb') as f:
                data = pickle.load(f)
                if isinstance(data, dict):
                    loaded_all_laminates = data.get('all_laminates', [])
                elif isinstance(data, list):
                    loaded_all_laminates = data
            print(f"Loaded {len(loaded_all_laminates)} laminates index.")
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
            print(f"Loaded {len(loaded_edge_swatches)} edge swatches index.")
    except Exception as e:
        print(f"Error loading edge swatches index: {e}")

    # नई Google Drive Indexing Pickle फाइल्स लोड करना
    try:
        if os.path.exists(lam_gdrive_path):
            with open(lam_gdrive_path, 'rb') as f:
                loaded_laminate_gdrive = pickle.load(f)
            print(f"Loaded {len(loaded_laminate_gdrive)} laminate GDrive paths.")
    except Exception as e:
        print(f"Error loading laminate GDrive index: {e}")

    try:
        if os.path.exists(edge_gdrive_path):
            with open(edge_gdrive_path, 'rb') as f:
                loaded_edge_gdrive = pickle.load(f)
            print(f"Loaded {len(loaded_edge_gdrive)} edge GDrive paths.")
    except Exception as e:
        print(f"Error loading edge GDrive index: {e}")

# Server start hote hi data load ho jayega
load_data()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "Flazzor Interior Backend is Running with GDrive Mapping!",
        "laminates_loaded": len(loaded_all_laminates),
        "swatches_loaded": len(loaded_edge_swatches),
        "gdrive_laminates": len(loaded_laminate_gdrive),
        "gdrive_swatches": len(loaded_edge_gdrive)
    }), 200

# ==================== IMAGE SERVING ROUTES (GDrive Linked) ====================
@app.route('/laminate/<path:filename>', methods=['GET'])
def serve_laminate_image(filename):
    # Google Drive G: ड्राइव से या लोकल फोल्डर से मैप करना
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # पहले G ड्राइव पाथ चेक करेंगे
    gdrive_base = r"G:\My Drive\Flazzor_Assets\laminate"
    
    # अगर filename में पूरा रिलेटिव पाथ मिल जाए
    matched_key = None
    for key in loaded_laminate_gdrive:
        if key.endswith(filename) or filename in key:
            matched_key = key
            break
            
    if matched_key:
        full_path = os.path.join(gdrive_base, matched_key.replace('/', os.sep))
        if os.path.exists(full_path):
            folder_name = os.path.dirname(full_path)
            file_name = os.path.basename(full_path)
            return send_from_directory(folder_name, file_name)

    # अगर G ड्राइव पर न मिले तो डिफ़ॉल्ट लोकल फोल्डर
    folder_path = os.path.join(base_dir, 'laminate')
    return send_from_directory(folder_path, filename)

@app.route('/edge/<path:filename>', methods=['GET'])
def serve_edge_image(filename):
    gdrive_base = r"G:\My Drive\Flazzor_Assets\edge"
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    matched_key = None
    for key in loaded_edge_gdrive:
        if key.endswith(filename) or filename in key:
            matched_key = key
            break
            
    if matched_key:
        full_path = os.path.join(gdrive_base, matched_key.replace('/', os.sep))
        if os.path.exists(full_path):
            folder_name = os.path.dirname(full_path)
            file_name = os.path.basename(full_path)
            return send_from_directory(folder_name, file_name)

    folder_path = os.path.join(base_dir, 'edge')
    return send_from_directory(folder_path, filename)

@app.route('/get_laminate_image', methods=['GET'])
def get_laminate_image():
    brand = request.args.get('brand')
    category = request.args.get('category', 'solid')
    filename = request.args.get('filename')
    
    if not brand or not filename:
        return jsonify({'error': 'Brand and filename are required'}), 400
        
    gdrive_base = r"G:\My Drive\Flazzor_Assets\laminate"
    target_key = f"{brand}/{category}/{filename}"
    
    if target_key in loaded_laminate_gdrive:
        full_path = os.path.join(gdrive_base, target_key.replace('/', os.sep))
        if os.path.exists(full_path):
            return send_from_directory(os.path.dirname(full_path), os.path.basename(full_path))
            
    # Fallback
    base_dir = os.path.dirname(os.path.abspath(__file__))
    folder_path = os.path.join(base_dir, 'laminate')
    target_path = os.path.join(brand, category, filename) if not filename.startswith(brand) else filename
    return send_from_directory(folder_path, target_path)
# ==============================================================

@app.route('/get_brands', methods=['GET'])
def get_brands():
    try:
        lam_brands = set()
        for item in loaded_all_laminates:
            b = item.get('brand')
            if b:
                lam_brands.add(str(b).strip())

        edge_brands = set()
        for item in loaded_edge_swatches:
            b = item.get('brand')
            if b:
                edge_brands.add(str(b).strip())

        return jsonify({
            'laminate_brands': sorted(list(lam_brands)),
            'edge_brands': sorted(list(edge_brands))
        }), 200
    except Exception as e:
        print(f"Error in get_brands: {e}")
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
        print(f"Error in get_laminate_list: {e}")
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
            if str(lam.get('brand', '')).strip() not in selected_brands:
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
            if str(swatch.get('brand', '')).strip() not in selected_brands:
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

@app.route('/match_catalog', methods=['POST'])
def match_catalog():
    try:
        brands_param = request.form.get('brands', '')
        selected_brands = [b.strip() for b in brands_param.split(',')] if brands_param else []
        
        target_brand = request.form.get('brand', '')
        target_filename = request.form.get('filename', '')
        
        if not selected_brands or selected_brands == ['']:
            return jsonify({'error': 'Kripya kam se kam ek Edge Banding company chunein!'}), 400

        target_lab = None
        for lam in loaded_all_laminates:
            if str(lam.get('filename', '')).strip() == target_filename.strip():
                target_lab = lam.get('mean_lab')
                break
                
        if target_lab is None:
            return jsonify({'error': 'Selected laminate LAB profile not found'}), 404

        results = []
        for swatch in loaded_edge_swatches:
            if str(swatch.get('brand', '')).strip() not in selected_brands:
                continue

            lab_dist = np.linalg.norm(target_lab - swatch['mean_lab'])
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)