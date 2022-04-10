extends Control

"""
Android Export Settings
----------------------------------------
Adb (from Android Studio)
C:/Users/[user]/AppData/Local/Android/Sdk/platform-tools/adb.exe

Jarsigner (where JDK been installed)
~/ojdkbuild/java-11-openjdk-11.0.4-1/bin/jarsigner.exe
or
~/jdk-14.0.1/bin/jarsigner.exe

Debug keystore
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999
Windows: C:/Users/[user]/.android/ or Windows: C:/Users/[user]
Linux: ~/.android/debug.keystore
----------------------------------------
"""

onready var audio_player = $AudioStreamPlayer
onready var progress_bar = $MarginC/VBoxC/PlayInfo/Progress
onready var dummy_progress_bar = $MarginC/VBoxC/PlayInfo/Progress/DummyProgress
onready var song_name_label = $MarginC/VBoxC/SongName
onready var now_time_label = $MarginC/VBoxC/PlayInfo/TimeNow
onready var end_time_label = $MarginC/VBoxC/PlayInfo/TimeEnd
onready var ab_btn = $MarginC/VBoxC/ControlAdvanced/AB
onready var explorer = $MarginC/VBoxC/Explorer
onready var control_basic = $MarginC/VBoxC/ControlBasic
onready var control_advanced = $MarginC/VBoxC/ControlAdvanced
onready var quit_confirm_popup = $QuitConfirm
onready var mode_btn = $MarginC/VBoxC/ControlAdvanced/Mode

var bg_paths = [
	'res://assets/graphics/bg_1.png',
	'res://assets/graphics/bg_2.jpg',
	'res://assets/graphics/bg_3.jpg',
	'res://assets/graphics/bg_4.jpg'
]
var bg_now = 0

var skipping_time = 10

var is_ab_on = false

var audio_playing = ''

var ab = [0, 0]
enum AB_STATES { WAIT_B, ACTIVE, INACTIVE }
var ab_state = AB_STATES.INACTIVE

var modes = ['solo_stop', 'solo_loop', 'all_loop', 'shuffle']
var current_mode = 0


func _process(delta):
	if audio_player.stream:
		dummy_progress_bar.value = audio_player.get_playback_position() / audio_player.stream.get_length() * progress_bar.max_value
	
		now_time_label.text = audio_length_to_clock(int(audio_player.get_playback_position()))
	
	if is_ab_on:
		if audio_player.get_playback_position() > ab[1]:
			audio_player.seek(ab[0])


func audio_length_to_clock(length):
	var seconds = int(length) % 60
	var minutes = int(length / 60)
	#var hours = int(minutes / 60)
	#minutes = minutes % 60
	
	var time_string = '%d:%2d' % [minutes, seconds]
	
	return time_string

# Hotload aduio
func play_audio(audio_url):
	audio_player.set_stream(hot_load_audio(audio_url, audio_url.get_extension()))
	audio_player.get_stream().loop = modes[current_mode] == 'solo_loop'
	audio_player.play()
	control_basic.get_node('Play').text = "||"
	
	audio_player.stream_paused = false
	
	song_name_label.text = audio_url.get_file().get_basename()

	end_time_label.text = audio_length_to_clock(int(audio_player.stream.get_length()))


func hot_load_audio(path, type):
	var new_file = File.new()
	new_file.open(path, File.READ)
	var bytes = new_file.get_buffer(new_file.get_len())
	
	var stream
	if type == 'ogg':
		stream = AudioStreamOGGVorbis.new()
	elif type == 'mp3':
		stream = AudioStreamMP3.new()
	else:
		return null
	
	stream.data = bytes
	stream.loop = false
	new_file.close()
	
	return stream


func _on_Play_pressed():
	if not audio_player.stream: return
	
	# If paused
	if audio_player.stream_paused:
		audio_player.stream_paused = false
		control_basic.get_node('Play').text = "||"
		
		# If stopped
		if not audio_player.playing:
			audio_player.play()
	else:
		audio_player.stream_paused = true
		control_basic.get_node('Play').text = ">"
	return


# When the audio player stopped
func _on_AudioStreamPlayer_finished():
	if modes[current_mode] == "solo_loop":
		audio_player.play()
		control_basic.get_node('Play').text = "||"
	else:
		audio_player.stream_paused = true
		control_basic.get_node('Play').text = ">"


func _on_PlayProgress_value_changed(value):
	if not audio_player.stream: return
	
	var ratio = value / progress_bar.max_value
	
	var to_position = ratio * audio_player.stream.get_length()
	
	if audio_player.playing:
		audio_player.seek(to_position)
	else:
		audio_player.play(to_position)
	
	return


func _on_Backward_pressed():
	if not audio_player.stream: return
	
	var to_position = audio_player.get_playback_position() - skipping_time
	
	if is_ab_on:
		to_position = clamp(to_position, ab[0], ab[1])
	else:
		to_position = clamp(to_position, 0, audio_player.stream.get_length())
	
	audio_player.seek(to_position)
	return


func _on_Forward_pressed():
	if not audio_player.stream: return
	
	var to_position = audio_player.get_playback_position() + skipping_time
	
	if is_ab_on:
		to_position = clamp(to_position, ab[0], ab[1])
		audio_player.seek(to_position)
	else:
		to_position = clamp(to_position, 0, audio_player.stream.get_length())
	
		if to_position == audio_player.stream.get_length():
			audio_player.stop()
		else:
			audio_player.seek(to_position)
	return
	

func _on_Explorer_file_selected(full_file_path):
	play_audio(full_file_path)
	audio_playing = full_file_path
	return


func _on_AB_pressed():
	if not audio_player.stream: return
	
	match ab_state:
		AB_STATES.INACTIVE:
			ab[0] = audio_player.get_playback_position()
			ab_state = AB_STATES.WAIT_B
		AB_STATES.WAIT_B:
			ab[1] = audio_player.get_playback_position()
			
			# B has to be after A
			if ab[1] <= ab[0]:
				ab = [0, 0]
				ab_state = AB_STATES.INACTIVE
			else:
				audio_player.seek(ab[0])
				is_ab_on = true
				ab_state = AB_STATES.ACTIVE
		AB_STATES.ACTIVE:
			ab = [0, 0]
			is_ab_on = false
			ab_state = AB_STATES.INACTIVE
	
	match ab_state:
		AB_STATES.INACTIVE:
			ab_btn.text = "A>"
		AB_STATES.WAIT_B:
			ab_btn.text = ">B"
		AB_STATES.ACTIVE:
			ab_btn.text = "AxB"


func _on_Confirm_pressed():
	get_tree().quit()


func _on_Explorer_quit_pressed():
	quit_confirm_popup.popup()


func _on_Cancel_pressed():
	quit_confirm_popup.hide()


func _on_Mode_pressed():
	current_mode += 1
	if current_mode >= len(modes):
		current_mode = 0
	
	match modes[current_mode]:
		"solo_stop":
			mode_btn.text = '>|'
		"solo_loop":
			mode_btn.text = '>1<'
		"all_loop":
			mode_btn.text = '>x<'
		"shuffle":
			mode_btn.text = 'x>'
