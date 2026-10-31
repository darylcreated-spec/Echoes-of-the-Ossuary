import os
import re
import sys
from pathlib import Path

WORKSPACE = Path(r"c:\Antigravity Projects\Game")
ASSETS_DIR = WORKSPACE / "assets"
SRC_DIR = WORKSPACE / "src"
SCENES_DIR = WORKSPACE / "scenes"
BRAIN_DIR = Path(r"C:\Users\daryl\.gemini\antigravity\brain\b85f0ffa-34bf-4cb5-a1fb-9879dd096756")

print("=" * 70)
print("   ECHOES OF THE OSSUARY — COMPREHENSIVE ASSET AUDIT TOOL   ")
print("=" * 70)

# 1. Index all files on disk
disk_assets = {}
for root, dirs, files in os.walk(ASSETS_DIR):
    for f in files:
        if f.endswith(".import") or f.endswith(".bin"):
            continue
        full_p = Path(root) / f
        rel_p = full_p.relative_to(WORKSPACE).as_posix()
        res_p = f"res://{rel_p}"
        disk_assets[res_p] = full_p

print(f"[*] Total unique asset files on disk: {len(disk_assets)}")

# 2. Extract all asset references from GDScript code
code_assets = set()
path_pattern = re.compile(r'res://assets/[a-zA-Z0-9_\-\.\/]+')

for root, dirs, files in os.walk(SRC_DIR):
    for f in files:
        if f.endswith(".gd"):
            content = (Path(root) / f).read_text(encoding="utf-8", errors="ignore")
            for m in path_pattern.findall(content):
                code_assets.add(m)

for root, dirs, files in os.walk(SCENES_DIR):
    for f in files:
        if f.endswith(".gd") or f.endswith(".tscn"):
            content = (Path(root) / f).read_text(encoding="utf-8", errors="ignore")
            for m in path_pattern.findall(content):
                code_assets.add(m)

# Add dynamically constructed paths
animals = ["Bull", "Cow", "Deer", "Fox", "Horse", "Horse_White", "Stag", "Wolf"]
for a in animals:
    code_assets.add(f"res://assets/characters/animals/{a}.glb")

skeletons = ["Skeleton_Warrior", "Skeleton_Minion", "Skeleton_Mage", "Skeleton_Rogue"]
for s in skeletons:
    code_assets.add(f"res://assets/characters/skeletons/{s}.glb")

adventurers = ["Knight", "Rogue", "Mage", "Barbarian", "Rogue_Hooded"]
for adv in adventurers:
    code_assets.add(f"res://assets/characters/adventurers/{adv}.glb")

weapons = ["sword_1handed", "sword_2handed", "dagger", "staff", "axe_2handed", "shield_square"]
for w in weapons:
    code_assets.add(f"res://assets/weapons/{w}.glb")

print(f"[*] Total unique asset paths referenced in code/gameplay: {len(code_assets)}")

# 3. Extract asset references from all planning documents
plan_assets = set()
for md_file in BRAIN_DIR.glob("*.md"):
    content = md_file.read_text(encoding="utf-8", errors="ignore")
    # Matches strings ending in .glb, .gltf, .ogg, .mp3, .wav, .png
    matches = re.findall(r'[a-zA-Z0-9_\-]+\.(?:glb|gltf|ogg|mp3|wav|png)', content)
    for m in matches:
        plan_assets.add(m)

print(f"[*] Total asset filenames referenced across development plans: {len(plan_assets)}")

# 4. Check Resolution
verified_exact = []
verified_compound = [] # e.g. .glb requested, found .gltf.glb or .gltf
verified_procedural = [] # procedural builders in AssetLoader or AudioManager
missing_assets = []

PROCEDURAL_PROPS = {"fireplace", "anvil", "ingot_stacked"}
PROCEDURAL_AUDIO = {"bgm_tavern", "bgm_castle", "bgm_forge", "bgm_boss", "sfx_victory_fanfare"}

for ref in sorted(code_assets):
    # Skip directory prefixes
    if ref.endswith("/"):
        continue

    # Check exact
    if ref in disk_assets:
        verified_exact.append(ref)
        continue

    # Check candidates as in AssetLoader.gd
    resolved = False
    candidates = []
    if ref.endswith(".glb"):
        candidates.append(ref.replace(".glb", ".gltf.glb"))
        candidates.append(ref.replace(".glb", ".gltf"))
    elif ref.endswith(".gltf"):
        candidates.append(ref + ".glb")
        candidates.append(ref.replace(".gltf", ".gltf.glb"))
        candidates.append(ref.replace(".gltf", ".glb"))

    for c in candidates:
        if c in disk_assets:
            verified_compound.append((ref, c))
            resolved = True
            break
            
    if resolved:
        continue

    # Check procedural fallback support
    stem = Path(ref).stem
    if any(p in ref for p in PROCEDURAL_PROPS):
        verified_procedural.append((ref, "Procedural 3D Mesh in AssetLoader._create_procedural_prop()"))
        continue
    if any(a in ref for a in PROCEDURAL_AUDIO):
        verified_procedural.append((ref, "Procedural 16-bit Synth Stream in AudioManager._generate_procedural_sfx()"))
        continue

    missing_assets.append(ref)

# Summary
print("\n" + "=" * 70)
print("AUDIT RESULTS SUMMARY")
print("=" * 70)
print(f"1. Verified Exact on Disk:              {len(verified_exact)}")
print(f"2. Verified via Compound Auto-Resolve: {len(verified_compound)}")
print(f"3. Verified via In-Engine Procedural:   {len(verified_procedural)}")
print(f"4. Missing / Unresolved in Code:        {len(missing_assets)}")

if missing_assets:
    print("\n[!] MISSING ASSET REFERENCES IN CODE:")
    for m in missing_assets:
        print(f"  - {m}")
else:
    print("\n[+] SUCCESS: ALL referenced code assets are 100% resolved and verified!")

print("\n" + "=" * 70)
print("PLANNING ASSET CROSS-REFERENCE AUDIT")
print("=" * 70)
plan_found = []
plan_missing = []
all_disk_filenames = {Path(p).name.lower() for p in disk_assets.keys()}

for p_name in sorted(plan_assets):
    # Strip compound extensions or check variations
    base = p_name.lower()
    found = False
    if base in all_disk_filenames:
        found = True
    elif (base + ".glb") in all_disk_filenames:
        found = True
    elif base.replace(".glb", ".gltf.glb") in all_disk_filenames:
        found = True
    elif base.replace(".glb", ".gltf") in all_disk_filenames:
        found = True
    elif base.replace(".gltf", ".gltf.glb") in all_disk_filenames:
        found = True
    elif any(base.startswith(p) for p in PROCEDURAL_PROPS) or any(base.startswith(a) for a in PROCEDURAL_AUDIO):
        found = True

    if found:
        plan_found.append(p_name)
    else:
        plan_missing.append(p_name)

print(f"Plan Assets Found / Accounted For:  {len(plan_found)}")
print(f"Plan Assets Missing / Not on Disk: {len(plan_missing)}")
if plan_missing:
    print("\nPlan assets not found on disk:")
    for pm in plan_missing:
        print(f"  - {pm}")

print("=" * 70)
