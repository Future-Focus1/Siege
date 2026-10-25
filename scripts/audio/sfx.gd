class_name Sfx
extends RefCounted

static var _player: AudioStreamPlayer


static func play(kind: String) -> void:
	if not Game.allow_sfx():
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.bus = "Master"
		tree.root.add_child(_player)
	_player.stream = _make(kind)
	_player.pitch_scale = randf_range(0.94, 1.06)
	_player.play()


static func _make(kind: String) -> AudioStreamWAV:
	var freq := 210.0
	var dur := 0.09
	var noise := 0.25
	match kind:
		"shot":
			freq = 96.0
			dur = 0.16
			noise = 0.5
		"break":
			freq = 150.0
			dur = 0.18
			noise = 0.8
		"collapse":
			freq = 64.0
			dur = 0.32
			noise = 0.72
		_:
			freq = 210.0
	var rate := 22050
	var count := int(float(rate) * dur)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var walk := 0.17
	for i in count:
		var t := float(i) / float(rate)
		var env := 1.0 - float(i) / float(count)
		env *= env
		walk = fmod(walk * 13.0 + 0.173, 1.0)
		var sample := (sin(TAU * freq * t) * (1.0 - noise) + (walk * 2.0 - 1.0) * noise) * env * 0.32
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
