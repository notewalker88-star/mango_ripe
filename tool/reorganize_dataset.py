"""
Reorganize Mango Dataset to Eliminate Data Leakage
--------------------------------------------------
Ensures that:
1. No burst shots or capture sessions are shared between Train and Test.
2. For Overripe, no augmented variations of the same original source image
   appear in both Train and Test.
"""

import os
import shutil
import random
from datetime import datetime
from collections import defaultdict

random.seed(42)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Dataset"))
TRAIN_DIR = os.path.join(BASE_DIR, "Train")
TEST_DIR = os.path.join(BASE_DIR, "Test")

CLASSES = ['Unripe', 'Partially Ripe', 'Fully Ripe', 'Overripe']

def get_all_files():
    data = defaultdict(list)
    for cls in CLASSES:
        for split in ['Train', 'Test']:
            split_dir = os.path.join(BASE_DIR, split, cls)
            if not os.path.exists(split_dir):
                continue
            for f in os.listdir(split_dir):
                if not f.startswith('.'):
                    full_p = os.path.join(split_dir, f)
                    data[cls].append((f, full_p))
    return data

def cluster_phone_images(files):
    # Sort by timestamp in filename IMGYYYYMMDDHHMMSS
    phone_files = [x for x in files if x[0].startswith('IMG')]
    other_files = [x for x in files if not x[0].startswith('IMG')]
    
    phone_files.sort(key=lambda x: x[0])
    clusters = []
    current_cluster = []
    prev_dt = None
    
    for f, p in phone_files:
        try:
            dt = datetime.strptime(f[3:17], '%Y%m%d%H%M%S')
        except Exception:
            dt = None
        
        if prev_dt is not None and dt is not None and (dt - prev_dt).total_seconds() > 60:
            clusters.append(current_cluster)
            current_cluster = [(f, p)]
        else:
            current_cluster.append((f, p))
        prev_dt = dt
        
    if current_cluster:
        clusters.append(current_cluster)
        
    # Treat other files as individual items or cluster by name
    if other_files:
        for f, p in other_files:
            clusters.append([(f, p)])
            
    return clusters

def cluster_overripe_images(files):
    # Group by base source filename
    groups = defaultdict(list)
    for f, p in files:
        base = f.replace('aug_', '').split('_white')[0].strip()
        groups[base].append((f, p))
    return list(groups.values())

def split_clusters(clusters, target_test_ratio=0.15):
    random.shuffle(clusters)
    total_items = sum(len(c) for c in clusters)
    target_test_items = int(total_items * target_test_ratio)
    
    # Sort clusters descending by size so we can greedily pack
    # or use knapsack/greedy approach to hit target test count closely
    test_clusters = []
    train_clusters = []
    current_test_count = 0
    
    # Sort clusters by size
    sorted_clusters = sorted(clusters, key=lambda c: len(c))
    
    for c in sorted_clusters:
        if current_test_count + len(c) <= target_test_items or (current_test_count == 0 and len(c) < total_items):
            test_clusters.append(c)
            current_test_count += len(c)
        else:
            train_clusters.append(c)
            
    train_files = [item for c in train_clusters for item in c]
    test_files = [item for c in test_clusters for item in c]
    return train_files, test_files

def reorganize():
    print("Collecting current dataset...")
    all_data = get_all_files()
    
    # Temporary staging directory to avoid collision during move
    staging_dir = os.path.join(BASE_DIR, "staging_temp")
    os.makedirs(staging_dir, exist_ok=True)
    
    summary = {}
    
    for cls in CLASSES:
        files = all_data[cls]
        print(f"\nProcessing class: {cls} (total: {len(files)} files)...")
        
        if cls == 'Overripe':
            clusters = cluster_overripe_images(files)
        else:
            clusters = cluster_phone_images(files)
            
        print(f"  Identified {len(clusters)} distinct subject/session clusters.")
        train_items, test_items = split_clusters(clusters, target_test_ratio=0.15)
        
        print(f"  Allocated -> Train: {len(train_items)} images, Test: {len(test_items)} images")
        summary[cls] = {'train': len(train_items), 'test': len(test_items), 'clusters': len(clusters)}
        
        # Move files to staging first
        for f, p in train_items:
            dest = os.path.join(staging_dir, "Train", cls)
            os.makedirs(dest, exist_ok=True)
            shutil.copy2(p, os.path.join(dest, f))
            
        for f, p in test_items:
            dest = os.path.join(staging_dir, "Test", cls)
            os.makedirs(dest, exist_ok=True)
            shutil.copy2(p, os.path.join(dest, f))
            
    # Now replace Train and Test with staged folders
    for cls in CLASSES:
        for split in ['Train', 'Test']:
            d = os.path.join(BASE_DIR, split, cls)
            if os.path.exists(d):
                shutil.rmtree(d)
            staged = os.path.join(staging_dir, split, cls)
            shutil.move(staged, d)
            
    shutil.rmtree(staging_dir, ignore_errors=True)
    
    print("\n" + "="*50)
    print("DATASET REORGANIZATION COMPLETE (NO DATA LEAKAGE)")
    print("="*50)
    for cls, cnt in summary.items():
        print(f"  {cls:<16}: Train = {cnt['train']:<4} | Test = {cnt['test']:<3} | Clusters = {cnt['clusters']}")
    print("="*50)

if __name__ == "__main__":
    reorganize()
