import os
import pickle
import cv2
import numpy as np
from flask import Flask, request, jsonify, redirect, send_file
from flask_cors import CORS
import io
import urllib.request

app = Flask(__name__)
CORS(app)

loaded_all_laminates = []
loaded_edge_swatches = []

# Supabase Public Storage बेस यूआरएल
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

load_data()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "Flazzor Interior Backend is Running with Supabase Cloud Storage!",
        "laminates_loaded": len(loaded_all_laminates),
        "swatches_loaded": len(loaded_edge_swatches)
    }), 200

# ==================== IMAGE SERVING ROUTES (Fixed & Safe) ====================
@app.route('/laminate/<path:filename>', methods=['GET'])
def serve_laminate_image(filename):
    safe_filename = filename.replace("[", "_").replace("]", "_")
    
    # अगर फाइल नाम में पहले से ही पाथ शामिल है
    if "/" in filename:
        cloud_url = f"{SUPABASE_PUBLIC_URL}/laminate/{safe_filename}"
        return redirect(cloud_url)
        
    # पिकल से ब्रांड और कैटेगरी ढूंढकर सटीक पाथ बनाना
    for lam in loaded_all_laminates:
        if lam.get('filename') == filename or filename in lam.get('filename', ''):
            brand = str(lam.get('brand', '')).strip()
            category = str(lam.get('category', 'solid')).strip()
            if brand:
                cloud_url = f"{SUPABASE_PUBLIC_URL}/laminate/{brand}/{category}/{safe_filename}"
                return redirect(cloud_url)
                
    cloud_url = f"{SUPABASE_PUBLIC_URL}/laminate/{safe_filename}"
    return redirect(cloud_url)

@app.route('/edge/<path:filename>', methods=['GET'])
def serve_edge_image(filename):
    safe_filename = filename.replace("[", "_").replace("]", "_")
    
    if "/" in filename:
        cloud_url = f"{SUPABASE_PUBLIC_URL}/edge/{safe_filename}"
        return redirect(cloud_url)
        
    for swatch in loaded_edge_swatches:
        if swatch.get('filename') == filename or filename in swatch.get('filename', ''):
            brand = str(swatch.get('brand', '')).strip()
            category = str(swatch.get('category', 'solid')).strip()
            if brand:
                cloud_url = f"{SUPABASE_PUBLIC_URL}/edge/{brand}/{category}/{safe_filename}"
                return redirect(cloud_url)
                
    cloud_url = f"{SUPABASE_PUBLIC_URL}/edge/{safe_filename}"
    return redirect(cloud_url)

@app.route('/get_laminate_image', methods=['GET'])
def get_laminate_image():
    brand = request.args.get('brand')
    category = request.args.get('category', 'solid')
    filename = request.args.get('filename')
    
    if not brand or not filename:
        return jsonify({'error': 'Brand and filename are required'}), 400
        
    target_path = f"{brand}/{category}/{filename}" if not filename.startswith(brand) else filename
    safe_path = target_path.replace("[", "_").replace("]", "_")
    cloud_url = f"{SUPABASE_PUBLIC_URL}/laminate/{safe_path}"
    return redirect(cloud_url)
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
        
        target_filename = request.form.get('filename', '')
        
        if not selected_brands or selected_brands == ['']:
            return jsonify({'error': 'Kripya kam se kam ek company chunein!'}), 400

        target_lab = None
        target_category = 'solid'
        for lam in loaded_all_laminates:
            if str(lam.get('filename', '')).strip() == target_filename.strip():
                target_lab = lam.get('mean_lab')
                target_category = lam.get('category', 'solid')
                break
                
        if target_lab is None:
            return jsonify({'error': 'Selected laminate LAB profile not found'}), 404

        results = []
        for swatch in loaded_edge_swatches:
            if str(swatch.get('brand', '')).strip() not in selected_brands:
                continue

            swatch_category = swatch.get('category', 'solid')
            if swatch_category != target_category:
                continue

            lab_dist = np.linalg.norm(target_lab - swatch['mean_lab'])
            if lab_dist > 120.0:
                continue

            score = max(0.0, 1.0 - (lab_dist / 120.0))
            results.append({
                'name': swatch.get('name'),
                'filename': swatch.get('filename'),
                'brand': swatch.get('brand'),
                'category': swatch_category,
                'score': float(score)
            })

        results = sorted(results, key=lambda x: x['score'], reverse=True)
        top_matches = results[:5]

        return jsonify({'matches': top_matches}), 200

    except Exception as e:
        print(f"Error in match_catalog: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== EXPORT REPORT AS JPG ROUTE ====================
@app.route('/export_report', methods=['POST'])
def export_report():
    try:
        data = request.get_json()
        matches = data.get('matches', [])
        tool_type = data.get('tool_type', 'Laminate Matching Report')

        if not matches:
            return jsonify({'error': 'No matches found to export'}), 400

        canvas_width = 800
        row_height = 130
        header_height = 100
        canvas_height = header_height + (len(matches) * row_height) + 50

        report_img = np.ones((canvas_height, canvas_width, 3), dtype=np.uint8) * 255

        cv2.rectangle(report_img, (0, 0), (canvas_width, header_height), (60, 35, 20), -1)
        cv2.putText(report_img, "FLAZZOR INTERIOR - MATCH REPORT", (30, 45), cv2.FONT_HERSHEY_DUPLEX, 0.9, (255, 255, 255), 2)
        cv2.putText(report_img, f"Tool: {tool_type} | Udaipur", (30, 75), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

        start_y = header_height + 20
        for i, match in enumerate(matches):
            brand = str(match.get('brand', '')).strip()
            name = match.get('name', '')
            score = float(match.get('score', 0)) * 100
            filename = match.get('filename', '')
            category = str(match.get('category', 'solid')).strip()

            y1 = start_y + (i * row_height)
            y2 = y1 + row_height - 10
            cv2.rectangle(report_img, (20,