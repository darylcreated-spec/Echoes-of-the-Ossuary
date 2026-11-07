#!/usr/bin/env python3
"""
Post-export processor for Godot 4.7.1 Web / PWA build targeting Vercel & GitHub.
1. Splits build/web/index.pck into <= 35 MB chunks (index.pck.part0..N) so every
   file stays well below GitHub and Vercel's 100 MB per-file limit.
2. Injects a transparent ReadableStream chunk-reassembler into build/web/index.html
   along with a custom Royal Medieval loading screen ("Created by daryl.created@gmail.com")
   and an "Install App (PWA)" prompt button.
3. Updates build/web/index.service.worker.js and build/web/index.manifest.json.
"""
import json
import math
import os
import re

WEB_DIR = os.path.join("build", "web")
CHUNK_SIZE = 35 * 1024 * 1024  # 35 MB per chunk


def split_pck_into_chunks() -> tuple[int, list[str]]:
    pck_path = os.path.join(WEB_DIR, "index.pck")
    meta_path = os.path.join(WEB_DIR, "pck_chunks.json")
    if os.path.exists(pck_path):
        total_size = os.path.getsize(pck_path)
        num_chunks = math.ceil(total_size / CHUNK_SIZE)
        chunk_names = []
        with open(pck_path, "rb") as src:
            for idx in range(num_chunks):
                part_name = f"index.pck.part{idx}"
                part_path = os.path.join(WEB_DIR, part_name)
                data = src.read(CHUNK_SIZE)
                with open(part_path, "wb") as dst:
                    dst.write(data)
                chunk_names.append(part_name)
                print(f" -> Created {part_name} ({len(data) / 1048576:.2f} MB)")
        os.remove(pck_path)
        meta = {"total_size": total_size, "chunks": chunk_names}
        with open(meta_path, "w", encoding="utf-8") as mf:
            json.dump(meta, mf, indent=2)
        return total_size, chunk_names
    elif os.path.exists(meta_path):
        with open(meta_path, "r", encoding="utf-8") as mf:
            meta = json.load(mf)
        return meta["total_size"], meta["chunks"]
    else:
        raise FileNotFoundError("Neither index.pck nor pck_chunks.json found in build/web")


def update_manifest() -> None:
    manifest_path = os.path.join(WEB_DIR, "index.manifest.json")
    manifest = {
        "name": "Echoes of the Ossuary",
        "short_name": "Ossuary",
        "description": "AA Medieval Action-RPG, Combined-Arms Siege & High-Seas Warfare — Created by daryl.created@gmail.com",
        "start_url": "./index.html",
        "display": "standalone",
        "orientation": "landscape",
        "background_color": "#0e111a",
        "theme_color": "#e8c252",
        "icons": [
            {"src": "index.144x144.png", "sizes": "144x144", "type": "image/png"},
            {"src": "index.180x180.png", "sizes": "180x180", "type": "image/png"},
            {"src": "index.512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"},
        ],
    }
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(" -> Updated index.manifest.json")


def update_service_worker(chunk_names: list[str]) -> None:
    sw_path = os.path.join(WEB_DIR, "index.service.worker.js")
    if not os.path.exists(sw_path):
        return
    with open(sw_path, "r", encoding="utf-8") as f:
        sw = f.read()
    cacheable_list = ["index.wasm"] + chunk_names
    sw = re.sub(
        r"const CACHEABLE_FILES = \[.*?\];",
        f"const CACHEABLE_FILES = {json.dumps(cacheable_list)};",
        sw,
    )
    with open(sw_path, "w", encoding="utf-8") as f:
        f.write(sw)
    print(" -> Updated index.service.worker.js with chunked PCK list")


def update_index_html(pck_total_size: int, chunk_names: list[str]) -> None:
    wasm_path = os.path.join(WEB_DIR, "index.wasm")
    wasm_size = os.path.getsize(wasm_path) if os.path.exists(wasm_path) else 39513091
    godot_config = {
        "args": [],
        "canvasResizePolicy": 2,
        "emscriptenPoolSize": 8,
        "ensureCrossOriginIsolationHeaders": False,
        "executable": "index",
        "experimentalVK": True,
        "fileSizes": {"index.pck": pck_total_size, "index.wasm": wasm_size},
        "focusCanvas": True,
        "gdextensionLibs": [],
        "godotPoolSize": 4,
        "serviceWorker": "index.service.worker.js",
    }

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0">
	<meta name="theme-color" content="#0e111a">
	<meta name="description" content="Echoes of the Ossuary — AA Medieval Action-RPG, Combined-Arms Siege & High-Seas Warfare. Created by daryl.created@gmail.com">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
	<title>Echoes of the Ossuary — Created by daryl.created@gmail.com</title>
	<link id="-gd-engine-icon" rel="icon" type="image/png" href="index.icon.png" />
	<link rel="apple-touch-icon" href="index.apple-touch-icon.png"/>
	<link rel="manifest" href="index.manifest.json">
	<style>
		* {{ box-sizing: border-box; }}
		html, body, #canvas {{
			margin: 0;
			padding: 0;
			border: 0;
			width: 100%;
			height: 100%;
		}}
		body {{
			color: #f4eed7;
			background-color: #0b0e17;
			overflow: hidden;
			touch-action: none;
			font-family: Georgia, "Times New Roman", serif;
		}}
		#canvas {{
			display: block;
		}}
		#canvas:focus {{
			outline: none;
		}}
		#status {{
			position: fixed;
			inset: 0;
			background: radial-gradient(circle at center, #182034 0%, #0b0e17 78%);
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			z-index: 20;
			padding: 24px;
		}}
		.royal-card {{
			max-width: 680px;
			width: 92%;
			background: rgba(14, 18, 29, 0.96);
			border: 3px solid #e6c155;
			border-radius: 14px;
			padding: 32px 28px;
			text-align: center;
			box-shadow: 0 20px 55px rgba(0, 0, 0, 0.78);
		}}
		.royal-title {{
			font-size: clamp(22px, 4vw, 34px);
			color: #ffdf78;
			margin: 0 0 8px 0;
			letter-spacing: 1px;
			text-shadow: 0 2px 8px rgba(0, 0, 0, 0.9);
		}}
		.royal-subtitle {{
			font-size: 13px;
			color: #c2cee8;
			margin-bottom: 16px;
			font-family: system-ui, -apple-system, sans-serif;
			letter-spacing: 0.6px;
		}}
		.creator-badge {{
			display: inline-block;
			background: rgba(38, 30, 14, 0.95);
			border: 1.5px solid #e6c155;
			border-radius: 8px;
			padding: 6px 18px;
			color: #ffe380;
			font-size: 15px;
			font-weight: bold;
			margin-bottom: 22px;
		}}
		.progress-track {{
			width: 100%;
			height: 18px;
			background: #090c14;
			border: 1.5px solid #6b5828;
			border-radius: 9px;
			overflow: hidden;
			margin-bottom: 10px;
		}}
		.progress-fill {{
			height: 100%;
			width: 2%;
			background: linear-gradient(90deg, #b8861e 0%, #f5d161 55%, #40e4da 100%);
			transition: width 0.15s ease-out;
		}}
		#status-label {{
			font-family: system-ui, -apple-system, sans-serif;
			font-size: 13px;
			color: #d6e0f5;
			margin-bottom: 6px;
		}}
		#status-notice {{
			display: none;
			background-color: #5b242c;
			border-radius: 8px;
			border: 1px solid #d45565;
			color: #ffe8eb;
			font-family: system-ui, sans-serif;
			padding: 12px;
			margin-top: 12px;
		}}
		#pwa-toolbar {{
			position: fixed;
			bottom: 8px;
			right: 12px;
			display: flex;
			gap: 8px;
			z-index: 15;
		}}
		.pwa-btn {{
			background: rgba(16, 21, 34, 0.88);
			color: #ffdf78;
			border: 1.5px solid #e6c155;
			border-radius: 7px;
			padding: 5px 11px;
			font-size: 12px;
			font-weight: 600;
			cursor: pointer;
			font-family: system-ui, sans-serif;
		}}
		.pwa-btn:hover {{
			background: rgba(38, 48, 74, 0.95);
		}}
	</style>
</head>
<body>
	<canvas id="canvas">Your browser does not support the HTML5 canvas tag.</canvas>

	<div id="pwa-toolbar">
		<button id="pwa-install-btn" class="pwa-btn" style="display:none;">📲 Install App (PWA)</button>
		<button id="pwa-fullscreen-btn" class="pwa-btn" title="Toggle Fullscreen">⛶ Fullscreen</button>
	</div>

	<div id="status">
		<div class="royal-card">
			<h1 class="royal-title">⚔️ ECHOES OF THE OSSUARY ⚔️</h1>
			<div class="royal-subtitle">CHRONICLES OF OAKHAVEN • COMBINED-ARMS SIEGE &amp; HIGH-SEAS WARFARE</div>
			<div class="creator-badge">👑 Created by daryl.created@gmail.com</div>
			<div class="progress-track">
				<div id="status-progress-fill" class="progress-fill"></div>
			</div>
			<div id="status-label">Initializing WebGL 2.0 &amp; Downloading Realm Assets...</div>
			<div id="status-notice"></div>
		</div>
	</div>

	<script>
	// Transparent Chunked PCK Stream Assembler for GitHub & Vercel (<35 MB chunks)
	(function() {{
		const PCK_CHUNKS = {json.dumps(chunk_names)};
		const PCK_TOTAL_SIZE = {pck_total_size};
		const nativeFetch = window.fetch.bind(window);

		window.fetch = function(resource, init) {{
			const url = (typeof resource === 'string') ? resource : (resource && resource.url ? resource.url : '');
			if (url.endsWith('index.pck')) {{
				const stream = new ReadableStream({{
					async start(controller) {{
						try {{
							for (let i = 0; i < PCK_CHUNKS.length; i++) {{
								const partUrl = url.replace(/index\\.pck$/, PCK_CHUNKS[i]);
								const resp = await nativeFetch(partUrl, init);
								if (!resp.ok) {{
									throw new Error('Failed loading chunk ' + PCK_CHUNKS[i] + ' (' + resp.status + ')');
								}}
								const reader = resp.body.getReader();
								while (true) {{
									const {{ done, value }} = await reader.read();
									if (done) break;
									controller.enqueue(value);
								}}
							}}
							controller.close();
						}} catch (err) {{
							controller.error(err);
						}}
					}}
				}});
				return Promise.resolve(new Response(stream, {{
					status: 200,
					statusText: 'OK',
					headers: {{
						'Content-Type': 'application/octet-stream',
						'Content-Length': String(PCK_TOTAL_SIZE)
					}}
				}}));
			}}
			return nativeFetch(resource, init);
		}};
	}})();
	</script>

	<script src="index.js"></script>
	<script>
	const GODOT_CONFIG = {json.dumps(godot_config)};
	const GODOT_THREADS_ENABLED = false;
	const engine = new Engine(GODOT_CONFIG);

	(function () {{
		const statusOverlay = document.getElementById('status');
		const statusProgressFill = document.getElementById('status-progress-fill');
		const statusLabel = document.getElementById('status-label');
		const statusNotice = document.getElementById('status-notice');
		const installBtn = document.getElementById('pwa-install-btn');
		const fullscreenBtn = document.getElementById('pwa-fullscreen-btn');

		// Register PWA Service Worker proactively
		if ('serviceWorker' in navigator && GODOT_CONFIG.serviceWorker) {{
			window.addEventListener('load', function() {{
				navigator.serviceWorker.register(GODOT_CONFIG.serviceWorker).catch(function(err) {{
					console.warn('PWA Service Worker registration note:', err);
				}});
			}});
		}}

		// Handle Install App (PWA) prompt
		let deferredPrompt = null;
		window.addEventListener('beforeinstallprompt', (e) => {{
			e.preventDefault();
			deferredPrompt = e;
			installBtn.style.display = 'inline-block';
		}});
		installBtn.addEventListener('click', async () => {{
			if (!deferredPrompt) return;
			deferredPrompt.prompt();
			await deferredPrompt.userChoice;
			deferredPrompt = null;
			installBtn.style.display = 'none';
		}});

		fullscreenBtn.addEventListener('click', () => {{
			if (!document.fullscreenElement) {{
				document.documentElement.requestFullscreen().catch(() => {{}});
			}} else {{
				document.exitFullscreen().catch(() => {{}});
			}}
		}});

		function displayFailureNotice(err) {{
			console.error(err);
			statusNotice.style.display = 'block';
			statusNotice.textContent = (err instanceof Error) ? err.message : String(err);
		}}

		const missing = Engine.getMissingFeatures({{ threads: GODOT_THREADS_ENABLED }});
		if (missing.length !== 0) {{
			displayFailureNotice('Missing WebGL2 / WebAssembly browser features: ' + missing.join(', '));
		}} else {{
			engine.startGame({{
				'onProgress': function (current, total) {{
					if (current > 0 && total > 0) {{
						const pct = Math.min(100, Math.round((current / total) * 100));
						statusProgressFill.style.width = pct + '%';
						const curMB = (current / 1048576).toFixed(1);
						const totMB = (total / 1048576).toFixed(1);
						statusLabel.textContent = 'Loading Realm Assets: ' + curMB + ' MB / ' + totMB + ' MB (' + pct + '%)';
					}}
				}},
			}}).then(() => {{
				statusOverlay.remove();
			}}, displayFailureNotice);
		}}
	}}());
	</script>
</body>
</html>
"""
    index_path = os.path.join(WEB_DIR, "index.html")
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(" -> Updated index.html with Royal Medieval PWA shell & Chunked PCK Stream Assembler")


if __name__ == "__main__":
    os.makedirs("build", exist_ok=True)
    with open(os.path.join("build", ".gdignore"), "w", encoding="utf-8") as gdi:
        gdi.write("")
    for fn in os.listdir(WEB_DIR):
        if fn.endswith(".import"):
            os.remove(os.path.join(WEB_DIR, fn))
    total_sz, chunks = split_pck_into_chunks()
    update_manifest()
    update_service_worker(chunks)
    update_index_html(total_sz, chunks)
    print("PWA post-processing complete!")
