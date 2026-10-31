extends Node

# Audio buses / pools
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player_a: AudioStreamPlayer = null
var _bgm_player_b: AudioStreamPlayer = null
var _active_bgm_idx: int = 0
var _crossfade_tween: Tween = null
var _current_bgm_key: String = ""
var _audio_cache: Dictionary = {}

const SFX_PATHS: Dictionary = {
	"sword_swing": "res://assets/audio/sfx_sword_swing.ogg",
	"sword_swing_heavy": "res://assets/audio/sfx_sword_swing_heavy.ogg",
	"hit_flesh": "res://assets/audio/sfx_hit_flesh.ogg",
	"skeleton_bones": "res://assets/audio/sfx_hit_flesh.ogg",
	"chest_open": "res://assets/audio/sfx_chest_open.ogg",
	"dash": "res://assets/audio/sfx_sword_swing.ogg",
	"bgm_dungeon": "res://assets/audio/bgm_dungeon_loop.ogg",
	"bgm_overworld": "res://assets/audio/bgm_overworld.ogg",
	"bgm_market": "res://assets/audio/bgm_market.mp3",
	"bgm_tavern": "res://assets/audio/bgm_tavern.ogg",
	"bgm_castle": "res://assets/audio/bgm_castle.ogg",
	"bgm_forge": "res://assets/audio/bgm_forge.ogg",
	"bgm_boss": "res://assets/audio/bgm_boss.ogg",
	"sfx_victory_fanfare": "res://assets/audio/sfx_victory_fanfare.ogg",
	"soul_pickup": "res://assets/audio/sfx_soul_pickup.ogg",
	"gold_pickup": "res://assets/audio/sfx_gold_pickup.ogg",
	"descent_sigil": "res://assets/audio/sfx_descent_sigil.ogg",
	"level_up": "res://assets/audio/sfx_level_up.ogg",
	"boon_acquired": "res://assets/audio/sfx_boon_acquired.ogg",
	"anvil_strike": "res://assets/audio/sfx_anvil_strike.ogg",
	"door_open": "res://assets/audio/sfx_door_open.ogg",
	"door_close": "res://assets/audio/sfx_door_close.ogg",
	"footstep": "res://assets/audio/sfx_footstep_0.ogg",
	"button_click": "res://assets/audio/sfx_button_click.wav",
	"ui_switch": "res://assets/audio/sfx_ui_switch.wav",
	"steed_whistle": "res://assets/audio/sfx_steed_whistle.ogg",
	"hoofbeat": "res://assets/audio/sfx_hoofbeat.ogg",
	"crossbow_shoot": "res://assets/audio/sfx_crossbow_shoot.ogg",
	"parry_ring": "res://assets/audio/sfx_parry_ring.ogg",
	"weapon_swap": "res://assets/audio/sfx_weapon_swap.ogg"
}

# Synth buffer fallbacks
var _synth_samples: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_load_or_generate_audio()

func _setup_audio_players() -> void:
	for i in range(12):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
		
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.name = "BGMPlayer_A"
	_bgm_player_a.bus = "Master"
	add_child(_bgm_player_a)

	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.name = "BGMPlayer_B"
	_bgm_player_b.bus = "Master"
	add_child(_bgm_player_b)

func _load_or_generate_audio() -> void:
	for key in SFX_PATHS.keys():
		var path = SFX_PATHS[key]
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			var stream = ResourceLoader.load(path)
			if stream is AudioStream:
				if key.begins_with("bgm_"):
					if "loop" in stream:
						stream.loop = true
				_audio_cache[key] = stream
		else:
			# Generate procedural AudioStreamWAV fallback so game is 100% playable with audio
			_audio_cache[key] = _generate_procedural_sfx(key)

func play_sfx(sfx_key: String, pitch_range: float = 0.08, volume_db: float = 0.0) -> void:
	if not _audio_cache.has(sfx_key):
		return
		
	var stream: AudioStream = _audio_cache[sfx_key]
	var player = _get_available_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
		player.volume_db = volume_db
		player.play()

func play_bgm(bgm_key: String = "bgm_overworld", volume_db: float = -12.0) -> void:
	crossfade_to_bgm(bgm_key, 0.85, volume_db)

func crossfade_to_bgm(bgm_key: String, duration: float = 0.85, target_volume_db: float = -12.0) -> void:
	if _current_bgm_key == bgm_key:
		return
	if not _audio_cache.has(bgm_key):
		return
		
	_current_bgm_key = bgm_key
	var new_stream: AudioStream = _audio_cache[bgm_key]
	
	var incoming_player = _bgm_player_b if _active_bgm_idx == 0 else _bgm_player_a
	var outgoing_player = _bgm_player_a if _active_bgm_idx == 0 else _bgm_player_b
	_active_bgm_idx = 1 if _active_bgm_idx == 0 else 0
	
	incoming_player.stream = new_stream
	incoming_player.volume_db = -60.0
	incoming_player.play()
	
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
		
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(incoming_player, "volume_db", target_volume_db, duration)
	if outgoing_player.playing:
		_crossfade_tween.tween_property(outgoing_player, "volume_db", -60.0, duration)
		_crossfade_tween.chain().tween_callback(outgoing_player.stop)

func stop_bgm() -> void:
	_current_bgm_key = ""
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if _bgm_player_a:
		_bgm_player_a.stop()
	if _bgm_player_b:
		_bgm_player_b.stop()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	# Steal first player if all busy
	return _sfx_players[0]

# --- PROCEDURAL SYNTHESIZER ---
func _generate_procedural_sfx(type: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var samples: PackedByteArray = PackedByteArray()
	
	match type:
		"sword_swing":
			# Whoosh: fast swept frequency with noise
			var duration: float = 0.18
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = sin(PI * (t / duration)) # Bell envelope
				var freq = lerp(600.0, 180.0, t / duration)
				var noise = randf_range(-0.5, 0.5)
				var val = (sin(2.0 * PI * freq * t) * 0.4 + noise * 0.6) * env * 0.7
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"dash":
			# Fast airy whoosh
			var duration: float = 0.22
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = pow(sin(PI * (t / duration)), 1.5)
				var noise = randf_range(-0.8, 0.8)
				var val = noise * env * 0.65
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"hit_flesh":
			# Heavy thud
			var duration: float = 0.15
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 28.0)
				var freq = lerp(160.0, 45.0, t / duration)
				var val = (sin(2.0 * PI * freq * t) * 0.8 + randf_range(-0.3, 0.3)) * env * 0.9
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"skeleton_bones":
			# Clattering bone snap
			var duration: float = 0.25
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 18.0)
				var click = 1.0 if (i % 350 < 40 or i % 720 < 40) else 0.0
				var freq = lerp(850.0, 300.0, t / duration)
				var val = (sin(2.0 * PI * freq * t) * 0.5 + randf_range(-0.4, 0.4) + click * 0.6) * env * 0.75
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"chest_open":
			# Arpeggiated chime fanfare (C5, E5, G5, C6)
			var duration: float = 0.6
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			var notes = [523.25, 659.25, 783.99, 1046.50]
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var note_idx = int(clamp((t / duration) * 4.0, 0.0, 3.0))
				var note_t = fmod(t, duration / 4.0)
				var env = exp(-note_t * 9.0)
				var freq = notes[note_idx]
				var val = (sin(2.0 * PI * freq * t) * 0.6 + sin(4.0 * PI * freq * t) * 0.25) * env * 0.6
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"soul_pickup":
			# Ascending chime (A5 -> C#6 -> E6)
			var duration: float = 0.35
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			var notes = [880.0, 1108.73, 1318.51]
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var note_idx = int(clamp((t / duration) * 3.0, 0.0, 2.0))
				var note_t = fmod(t, duration / 3.0)
				var env = exp(-note_t * 12.0)
				var freq = notes[note_idx]
				var val = (sin(2.0 * PI * freq * t) * 0.7 + sin(4.0 * PI * freq * t) * 0.2) * env * 0.6
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"descent_sigil":
			# Deep mystic cosmic portal warp hum
			var duration: float = 1.2
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = sin(PI * (t / duration))
				var sweep_freq = lerp(90.0, 320.0, sin(PI * t / duration))
				var sub_freq = 55.0
				var val = (sin(2.0 * PI * sweep_freq * t) * 0.5 + sin(2.0 * PI * sub_freq * t) * 0.5) * env * 0.8
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"level_up":
			# Triumphant fanfare
			var duration: float = 0.8
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			var notes = [440.0, 554.37, 659.25, 880.0]
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var note_idx = int(clamp((t / duration) * 4.0, 0.0, 3.0))
				var note_t = fmod(t, duration / 4.0)
				var env = exp(-note_t * 6.0)
				var freq = notes[note_idx]
				var val = (sin(2.0 * PI * freq * t) * 0.65 + sin(3.0 * PI * freq * t) * 0.25) * env * 0.7
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"footstep":
			# Subtle stone footstep
			var duration: float = 0.09
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 40.0)
				var noise = randf_range(-0.4, 0.4)
				var low_pop = sin(2.0 * PI * 95.0 * t) * 0.6
				var val = (low_pop + noise) * env * 0.4
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"button_click":
			# Crisp UI tick
			var duration: float = 0.04
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 80.0)
				var val = sin(2.0 * PI * 1200.0 * t) * env * 0.5
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"steed_whistle":
			# Piercing two-tone ascending equestrian whistle
			var duration: float = 0.42
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = sin(PI * (t / duration))
				var freq = lerp(1760.0, 2640.0, t / duration)
				var vibrato = sin(2.0 * PI * 14.0 * t) * 60.0
				var val = sin(2.0 * PI * (freq + vibrato) * t) * env * 0.75
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"hoofbeat":
			# Acoustic double-tap equestrian hoofbeat (clip-clop)
			var duration: float = 0.18
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				# First clop at 0.0s, second clop at 0.08s
				var t1 = t
				var env1 = exp(-t1 * 60.0)
				var pop1 = sin(2.0 * PI * 140.0 * t1) * env1
				
				var t2 = max(0.0, t - 0.08)
				var env2 = exp(-t2 * 65.0) if t >= 0.08 else 0.0
				var pop2 = sin(2.0 * PI * 190.0 * t2) * env2
				
				var wood = (pop1 * 0.7 + pop2 * 0.85) + randf_range(-0.1, 0.1) * (env1 + env2) * 0.3
				var val = wood * 0.8
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"crossbow_shoot":
			# Crisp mechanical string release snap & projectile whiz
			var duration: float = 0.22
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 32.0)
				var snap = (randf_range(-0.8, 0.8) * exp(-t * 90.0))
				var thrum = sin(2.0 * PI * lerp(340.0, 120.0, t / duration) * t) * env * 0.6
				var val = (snap * 0.6 + thrum * 0.5) * 0.85
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"parry_ring":
			# Brilliant ringing anvil deflection chime (2800 Hz + 5600 Hz harmonic)
			var duration: float = 0.65
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = exp(-t * 9.5)
				var ping1 = sin(2.0 * PI * 2793.8 * t) * 0.65
				var ping2 = sin(2.0 * PI * 5587.6 * t) * 0.25
				var sub_clack = sin(2.0 * PI * 440.0 * t) * exp(-t * 40.0) * 0.3
				var val = (ping1 + ping2 + sub_clack) * env * 0.85
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"weapon_swap":
			# Metallic blade draw / sheathe scrape
			var duration: float = 0.25
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var env = sin(PI * (t / duration))
				var scrape = randf_range(-0.5, 0.5) * env * 0.4
				var ring = sin(2.0 * PI * 1800.0 * t) * exp(-t * 18.0) * 0.4
				var val = (scrape + ring) * 0.75
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"bgm_dungeon":
			# Atmospheric brooding drone with slow subtle harmonic pulse
			var duration: float = 4.0
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var lfo = 0.6 + 0.4 * sin(2.0 * PI * 0.25 * t)
				var d1 = sin(2.0 * PI * 65.41 * t) * 0.45  # C2
				var d2 = sin(2.0 * PI * 98.00 * t) * 0.35  # G2
				var d3 = sin(2.0 * PI * 116.54 * t) * 0.25 # A#2
				var val = (d1 + d2 + d3) * lfo * 0.5
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"bgm_tavern":
			# Lively folk tavern lute arpeggio & bodhrán beat (4.0s loop)
			var duration: float = 4.0
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
			var chord_roots = [146.83, 174.61, 130.81, 196.00] # D3, F3, C3, G3
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var chord_idx = int(fmod(t, 4.0)) # 1 bar per chord
				var root_freq = chord_roots[chord_idx]
				var beat_t = fmod(t, 0.25) # 16th note arpeggios
				var env = exp(-beat_t * 14.0)
				# 4-note arpeggio step
				var arp_step = int(fmod(t * 4.0, 4.0))
				var note_mult = 1.0
				match arp_step:
					0: note_mult = 1.0
					1: note_mult = 1.2
					2: note_mult = 1.5
					3: note_mult = 2.0
				var lute = (sin(2.0 * PI * root_freq * note_mult * t) * 0.6 + sin(4.0 * PI * root_freq * note_mult * t) * 0.25) * env
				# Light folk tambourine/beat on beats 1 and 3
				var tamb_t = fmod(t, 0.5)
				var tamb_env = exp(-tamb_t * 30.0)
				var tamb = randf_range(-0.25, 0.25) * tamb_env
				var val = (lute * 0.65 + tamb * 0.35) * 0.75
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"bgm_castle":
			# Majestic imperial court royal fanfare & stately strings (4.8s loop)
			var duration: float = 4.8
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var lfo = 0.75 + 0.25 * sin(2.0 * PI * 0.42 * t)
				# Noble brass fourths and fifths
				var brass1 = sin(2.0 * PI * 146.83 * t) * 0.35 # D3
				var brass2 = sin(2.0 * PI * 220.00 * t) * 0.30 # A3
				var brass3 = sin(2.0 * PI * 293.66 * t) * 0.25 # D4
				var brass4 = sin(2.0 * PI * 369.99 * t) * 0.20 # F#4
				var strings_pad = sin(2.0 * PI * 73.42 * t) * 0.4 # D2 cello
				var val = (brass1 + brass2 + brass3 + brass4 + strings_pad) * lfo * 0.5
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"bgm_forge":
			# Rhythmic dwarven smithy pulse with anvil pings & warm furnace drone (3.2s loop)
			var duration: float = 3.2
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
			for i in range(total_frames):
				var t = float(i) / sample_rate
				# Low sub furnace rumble
				var sub_heat = (sin(2.0 * PI * 55.0 * t) + randf_range(-0.15, 0.15)) * 0.35
				# Anvil strike ping on beats (every 0.8s)
				var hit_t = fmod(t, 0.8)
				var hit_env = exp(-hit_t * 16.0)
				var anvil_ping = (sin(2.0 * PI * 1850.0 * t) * 0.6 + sin(2.0 * PI * 3700.0 * t) * 0.3) * hit_env
				var bass_thud = sin(2.0 * PI * 85.0 * t) * exp(-hit_t * 8.0) * 0.5
				var val = (sub_heat + anvil_ping * 0.5 + bass_thud * 0.4) * 0.65
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"bgm_boss":
			# High-tempo gothic battle orchestra with timpani triplets & driving brass (3.6s loop)
			var duration: float = 3.6
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
			for i in range(total_frames):
				var t = float(i) / sample_rate
				# Timpani drum pulse on 16th notes (approx 145 BPM)
				var beat_t = fmod(t, 0.207)
				var drum_env = exp(-beat_t * 22.0)
				var drum = (sin(2.0 * PI * lerp(90.0, 45.0, beat_t / 0.207) * t) * 0.8 + randf_range(-0.3, 0.3)) * drum_env
				# Tense gothic minor stabs (C3, Eb3, G3, B3)
				var stab_t = fmod(t, 0.828)
				var stab_env = exp(-stab_t * 9.0)
				var chord = (sin(2.0 * PI * 130.81 * t) + sin(2.0 * PI * 155.56 * t) + sin(2.0 * PI * 196.0 * t) + sin(2.0 * PI * 246.94 * t)) * 0.25 * stab_env
				# Dark sinister drone
				var drone = sin(2.0 * PI * 48.99 * t) * 0.3
				var val = (drum * 0.5 + chord * 0.4 + drone * 0.3) * 0.7
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		"sfx_victory_fanfare":
			# Triumphant ascending brass fanfare (1.5s)
			var duration: float = 1.5
			var total_frames = int(sample_rate * duration)
			samples.resize(total_frames * 2)
			var notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50]
			for i in range(total_frames):
				var t = float(i) / sample_rate
				var note_idx = int(clamp((t / duration) * 7.0, 0.0, 6.0))
				var note_t = fmod(t, duration / 7.0)
				var env = exp(-note_t * 5.5)
				var freq = notes[note_idx]
				var brass = (sin(2.0 * PI * freq * t) * 0.65 + sin(3.0 * PI * freq * t) * 0.25 + sin(4.0 * PI * freq * t) * 0.15) * env
				var val = brass * 0.75
				var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
				samples.encode_s16(i * 2, s16)

		_:
			samples.resize(100)

	stream.data = samples
	return stream
