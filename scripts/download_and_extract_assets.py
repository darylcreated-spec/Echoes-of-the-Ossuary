import os
import shutil
import subprocess

workspace = r"c:\Antigravity Projects\Game"
assets_dir = os.path.join(workspace, "assets")
temp_dir = os.path.join(workspace, "temp_git_assets")
os.makedirs(temp_dir, exist_ok=True)

repos = [
    {
        "name": "KayKit-Character-Pack-Skeletons-1.0",
        "url": "https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0.git",
        "dest": os.path.join(assets_dir, "characters", "skeletons")
    },
    {
        "name": "KayKit-Character-Pack-Adventures-1.0",
        "url": "https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0.git",
        "dest": os.path.join(assets_dir, "characters", "adventurers")
    },
    {
        "name": "KayKit-Dungeon-Remastered-1.0",
        "url": "https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0.git",
        "dest": os.path.join(assets_dir, "dungeon")
    }
]

weapons_dest = os.path.join(assets_dir, "weapons")
os.makedirs(weapons_dest, exist_ok=True)

print("=== Downloading and Ingesting Assets ===")

for repo in repos:
    target_clone = os.path.join(temp_dir, repo['name'])
    if not os.path.exists(target_clone):
        print(f"[*] Cloning {repo['name']}...")
        res = subprocess.run(["git", "clone", "--depth", "1", repo['url'], target_clone], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[-] Clone failed: {res.stderr}")
            continue
    else:
        print(f"[*] Found existing clone for {repo['name']}.")

    os.makedirs(repo['dest'], exist_ok=True)
    copied = 0
    for root, dirs, files in os.walk(target_clone):
        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext in ['.glb', '.gltf', '.bin', '.png']:
                src_path = os.path.join(root, f)
                # If it's a weapon/shield, copy to weapons too
                if any(k in f.lower() for k in ['sword', 'blade', 'shield', 'axe', 'staff', 'crossbow', 'dagger', 'bow']):
                    shutil.copy2(src_path, os.path.join(weapons_dest, f))
                
                shutil.copy2(src_path, os.path.join(repo['dest'], f))
                copied += 1

    print(f"[OK] Ingested {copied} files into {repo['dest']}")

print("=== Ingestion complete ===")
