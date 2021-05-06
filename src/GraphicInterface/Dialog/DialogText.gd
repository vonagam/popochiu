class_name DialogText
extends RichTextLabel
# Permite mostrar textos caracter por caracter en un RichTextLabel para aprove-
# char sus capacidades de animación y edición de fragmentos de texto.

signal animation_finished

export var wrap_width := 200
export var min_wrap_width := 120

var _secs_per_character := 1.0
var _wrapper := '[center]%s[/center]'
var _is_waiting_input := false
#  Estos valores se toman de la configuración hecha en el Editor --------------
var _max_width := rect_size.x
var _dflt_height := rect_size.y
#  ----------------------------------------------------------------------------
var _target_size := Vector2.ONE

onready var _tween: Tween = $Tween
onready var _label_dflt_size: Vector2 = $Label.rect_size


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Establecer la configuración inicial
	clear()
	modulate.a = 0.0
	_secs_per_character = E.text_speeds[0]
	
	# Conectarse a señales de los hijos
	_tween.connect('tween_all_completed', self, '_wait_input')
	
	# Conectarse a eventos del universo Chimpoko
	E.connect('text_speed_changed', self, 'change_speed')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func play_text(props: Dictionary) -> void:
	# Establecer el estado por defecto
	_is_waiting_input = false
	clear()
	push_color(props.color)
	append_bbcode(_wrapper % props.text)
	rect_size = Vector2(wrap_width, _dflt_height)

	# Se usa un Label para saber el ancho y alto que tendrá el RichTextLabel
	$Label.rect_size = Vector2(wrap_width, _dflt_height)
	$Label.text = text
	
	rect_position = props.position

	yield(get_tree(), 'idle_frame')
	
	_target_size = Vector2(
		wrap_width,
		_dflt_height + (($Label.get_line_count() - 1) * 14.0)
	)
	rect_size = _target_size
	$Label.rect_size = _target_size
	rect_position.y -= 6.0

	# Ajustar la posición en X del texto que dice el personaje
	rect_position.x -= rect_size.x / 2
	if rect_position.x < -16.0:
		_target_size.x = min_wrap_width
		_target_size.y = _dflt_height + (($Label.get_line_count() - 1) * 14.0)
		rect_size = _target_size
		$Label.rect_size = _target_size

		rect_position.x = 0.0
		rect_position.y -= 12.0
	elif rect_position.x + rect_size.x > E.game_width + 16.0:
		_target_size.x = min_wrap_width
		_target_size.y = _dflt_height + (($Label.get_line_count() - 1) * 14.0)
		rect_size = _target_size
		$Label.rect_size = _target_size

		rect_position.x = E.game_width - rect_size.x
		rect_position.y -= 12.0
	
	# Ajustar la posición en Y del texto que dice el personaje	
	rect_position.y -= _target_size.y
	rect_position.y += props.offset_y
#
#	# Si se quiere hacer de otro modo en el Inspector

	if _secs_per_character > 0.0:
		# Que el texto aparezca animado
		_tween.interpolate_property(
			self, 'percent_visible',
			0, 1,
			_secs_per_character * $Label.get_total_character_count(),
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween.start()

	modulate.a = 1.0


func stop() ->void:
	if modulate.a == 0.0:
		return

	if _is_waiting_input:
		_notify_completion()
	else:
		# Saltarse las animaciones
		_tween.stop_all()
		percent_visible = 1.0
		rect_size = _target_size
		_wait_input()


func hide() -> void:
	modulate.a = 0.0
	_tween.stop_all()
	_is_waiting_input = false


func change_speed(idx: int) -> void:
	_secs_per_character = E.text_speeds[idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _wait_input() -> void:
	_is_waiting_input = true


func _notify_completion() -> void:
	self.hide()
	emit_signal('animation_finished')
