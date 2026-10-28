extends Node

# Audio buses / pools
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer = null
var _audio_cache: Dictionary = {}

const SFX_PATHS: Dictionary = {
	"sword_swing": "res://assets/audio/sfx_sword_swing.ogg",
	"hit_flesh": "res://assets/audio/sfx_hit_flesh.ogg",
	"skeleton_bones": "res://assets/audio/sfx_skeleton_bones.ogg",
	"chest_open": "res://assets/audio/sfx_chest_open.ogg",
	"dash": "res://assets/audio/sfx_dash.ogg",
	"bgm_dungeon": "res://assets/audio/bgm_dungeon_loop.ogg",
	"soul_pickup": "res://assets/audio/sfx_soul_pickup.ogg",
	"descent_sigil": "res://assets/audio/sfx_descent_sigil.ogg",
	"level_up": "res://assets/audio/sfx_level_up.ogg",
	"footstep": "res://assets/audio/sfx_footstep.ogg",
	"button_click": "res://assets/audio/sfx_button_click.ogg"
}

# Synth buffer fallbacks
var _synth_samples: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_load_or_generate_audio()

func _setup_audio_players() -> void:
	# Create a pool of 8 SFX players to allow rapid concurrent audio
	for i in range(12):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
		
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

func _load_or_generate_audio() -> void:
	for key in SFX_PATHS.keys():
		var path = SFX_PATHS[key]
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			var stream = ResourceLoader.load(path)
			if stream is AudioStream:
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

func play_bgm(bgm_key: String = "bgm_dungeon", volume_db: float = -6.0) -> void:
	if not _audio_cache.has(bgm_key):
		return
	var stream: AudioStream = _audio_cache[bgm_key]
	if _bgm_player.stream != stream or not _bgm_player.playing:
		_bgm_player.stream = stream
		_bgm_player.volume_db = volume_db
		_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()

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

		_:
			samples.resize(100)

	stream.data = samples
	return stream
