"""
Mango Dataset Ingestion & Ingestion Helper
------------------------------------------
Allows you to easily add new batches/photos of real mangoes.

Usage:
  python tool/add_mango_samples.py --src path/to/my_mango_photos --cls "Fully Ripe" [--split Train]

Features:
- Validates that images can be decoded and aren't corrupted.
- Automatically handles naming and avoids collisions.
- Option to place into 'Train' or 'Test' (default: Train).
- Shows updated class totals across the dataset.
"""

import os
import sys
import shutil
import argparse
from PIL import Image

CLASSES = ['Unripe', 'Partially Ripe', 'Fully Ripe', 'Overripe']
DATASET_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Dataset"))

def validate_and_copy(src_dir, cls_name, target_split):
    if cls_name not in CLASSES:
        print(f"Error: Unknown class '{cls_name}'. Must be one of: {CLASSES}")
        sys.exit(1)
        
    dest_dir = os.path.join(DATASET_DIR, target_split, cls_name)
    os.makedirs(dest_dir, exist_ok=True)
    
    if not os.path.exists(src_dir):
        print(f"Error: Source path '{src_dir}' does not exist.")
        sys.exit(1)
        
    files = [f for f in os.listdir(src_dir) if not f.startswith('.')]
    added = 0
    skipped = 0
    
    print(f"\nImporting images for '{cls_name}' into {target_split}...")
    for f in files:
        src_path = os.path.join(src_dir, f)
        if not os.path.isfile(src_path):
            continue
        try:
            with Image.open(src_path) as img:
                img.verify() # Check integrity
            # Generate clean destination filename
            clean_name = f"new_{target_split.lower()}_{cls_name.lower().replace(' ', '_')}_{f}"
            dest_path = os.path.join(dest_dir, clean_name)
            shutil.copy2(src_path, dest_path)
            added += 1
        except Exception as e:
            print(f"  Skipping invalid image {f}: {e}")
            skipped += 1
            
    print(f"Done! Added: {added} images. Skipped: {skipped}.")
    print_dataset_summary()

def print_dataset_summary():
    print("\n" + "="*45)
    print("CURRENT DATASET IMAGE COUNTS")
    print("="*45)
    for split in ['Train', 'Test']:
        print(f"[{split}]")
        total = 0
        for c in CLASSES:
            p = os.path.join(DATASET_DIR, split, c)
            cnt = len([f for f in os.listdir(p) if not f.startswith('.')]) if os.path.exists(p) else 0
            total += cnt
            print(f"  {c:<16}: {cnt}")
        print(f"  Total {split:<10}: {total}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add new mango photos to the dataset.")
    parser.add_argument("--src", type=str, help="Folder containing the new photos.")
    parser.add_argument("--cls", type=str, choices=CLASSES, help="Mango ripeness class.")
    parser.add_argument("--split", type=str, choices=['Train', 'Test'], default="Train", help="Target split (default: Train).")
    parser.add_argument("--summary", action="store_true", help="Print dataset balance summary.")
    
    args = parser.parse_args()
    if args.summary or not args.src:
        print_dataset_summary()
    else:
        validate_and_copy(args.src, args.cls, args.split)
