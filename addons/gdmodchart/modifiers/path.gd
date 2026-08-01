extends ModchartModifier

const SWAG_WIDTH:float = 112.0
const HALF_WIDTH:float = 56.0
const PI_THIRD:float = PI / 3.0
const SCREEN_HEIGHT:float = 720.0

func get_id() -> String:
	return "tornado"

func get_sub_modifier_ids() -> Array[String]:
	return [
		"xmode", "zigzag", "zigzagPeriod", "zigzagOffset", "sawtooth", "sawtoothPeriod",
		"square", "squareOffset", "squarePeriod", "bounce", "bounceOffset", "bouncePeriod",
		"zigzagZ", "zigzagZPeriod", "zigzagZOffset", "bounceZ", "bounceZOffset", "bounceZPeriod",
		"digital", "digitalSteps", "digitalOffset", "digitalPeriod", "digitalZ", "digitalZSteps",
		"digitalZOffset", "digitalZPeriod", "tornadoPeriod", "tornadoOffset", "tornadoZ",
		"tornadoZPeriod", "tornadoZOffset", "tornadoTan", "tornadoTanPeriod", "tornadoTanOffset",
		"tornadoTanZ", "tornadoTanZPeriod", "tornadoTanZOffset", "itgTornado", "itgTornadoTan",
		"itgTornadoOffset", "itgTornadoPeriod", "itgTornadoTanOffset", "itgTornadoTanPeriod"
	]

func triangle(theta:float) -> float:
	return 2.0 * abs(2.0 * (theta / (2.0 * PI) - floor(theta / (2.0 * PI) + 0.5))) - 1.0

func square(theta:float) -> float:
	return 1.0 if sin(theta) >= 0.0 else -1.0

func scale_value(v:float, min1:float, max1:float, min2:float, max2:float) -> float:
	return min2 + (v - min1) * (max2 - min2) / (max1 - min1)

func get_digital_angle(y_offset:float, offset:float, period:float) -> float:
	return PI * (y_offset + (1.0 * offset)) / (SWAG_WIDTH + (period * SWAG_WIDTH))

func get_position(position:Vector3, origin:Variant, type:ModchartManager.ObjectType, direction:int, player:int) -> Vector3:
	var pos := position
	var diff:float = manager.adapter.get_note_time(origin) - manager.adapter.get_song_time() if type == ModchartManager.ObjectType.NOTE else 0
	var key_count:int = manager.adapter.get_key_count()
	var key_cunt:float = float(key_count - 1)
	
	# zigzag
	var zigzag = get_value(player, "zigzag")
	if zigzag != 0.0:
		var offset = get_value(player, "zigzagOffset")
		var period = get_value(player, "zigzagPeriod")
		var result:float = triangle(PI * (1.0 / (period + 1.0)) * ((diff + 100.0 * offset) / SWAG_WIDTH))
		pos.x += (zigzag * HALF_WIDTH) * result

	# zigzagZ
	var zigzagZ = get_value(player, "zigzagZ")
	if zigzagZ != 0.0:
		var offset = get_value(player, "zigzagZOffset")
		var period = get_value(player, "zigzagZPeriod")
		var result:float = triangle(PI * (1.0 / (period + 1.0)) * ((diff + 100.0 * offset) / SWAG_WIDTH))
		pos.z += (zigzagZ * HALF_WIDTH) * result

	# sawtooth
	var sawtooth = get_value(player, "sawtooth")
	if sawtooth != 0.0:
		var period = get_value(player, "sawtoothPeriod") + 1.0
		var p = (0.5 / period * diff) / SWAG_WIDTH
		pos.x += (sawtooth * SWAG_WIDTH) * (p - floor(p))

	# square
	var squareVal = get_value(player, "square")
	if squareVal != 0.0:
		var offset = get_value(player, "squareOffset")
		var period = get_value(player, "squarePeriod")
		var cum = (PI * (diff + offset) / (SWAG_WIDTH + (period * SWAG_WIDTH)))
		pos.x += squareVal * HALF_WIDTH * square(cum)

	# bounce
	var bounceVal = get_value(player, "bounce")
	if bounceVal != 0.0:
		var offset = get_value(player, "bounceOffset")
		var period = get_value(player, "bouncePeriod")
		if period != -1.0:
			var bounce = abs(sin((diff + offset) / (90.0 + 90.0 * period)))
			pos.x += bounceVal * HALF_WIDTH * bounce

	# bounceZ
	var bounceZVal = get_value(player, "bounceZ")
	if bounceZVal != 0.0:
		var offset = get_value(player, "bounceZOffset")
		var period = get_value(player, "bounceZPeriod")
		if period != -1.0:
			var bounce = abs(sin((diff + offset) / (90.0 + 90.0 * period)))
			pos.z += bounceZVal * HALF_WIDTH * bounce

	# xmode
	var xmode = get_value(player, "xmode")
	if xmode != 0.0:
		var mod = (player + 1) * 2 - 3
		pos.x += xmode * (diff * mod)

	# tornado
	var tornadoVal = get_value(player)
	if tornadoVal != 0.0:
		var playerColumn = direction % key_count
		var columnPhaseShift = (playerColumn * PI_THIRD) + get_value(player, "tornadoOffset")
		var phaseShift = (diff / 135.0) * (1.0 + get_value(player, "tornadoPeriod"))
		var returnReceptorToZeroOffsetX = (-cos(-columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt
		var offsetX = (-cos(phaseShift - columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt - returnReceptorToZeroOffsetX
		pos.x += offsetX * tornadoVal

	# tornadoTan
	var tornadoTanVal = get_value(player, "tornadoTan")
	if tornadoTanVal != 0.0:
		var playerColumn = direction % key_count
		var columnPhaseShift = (playerColumn * PI_THIRD) + get_value(player, "tornadoTanOffset")
		var phaseShift = (diff / 135.0) * (1.0 + get_value(player, "tornadoTanPeriod"))
		var returnReceptorToZeroOffsetX = (-cos(-columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt
		var offsetX = (-tan(phaseShift - columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt - returnReceptorToZeroOffsetX
		pos.x += offsetX * tornadoTanVal

	# tornadoZ
	var tornadoZVal = get_value(player, "tornadoZ")
	if tornadoZVal != 0.0:
		var playerColumn = direction % key_count
		var columnPhaseShift = (playerColumn * PI_THIRD) + get_value(player, "tornadoZOffset")
		var phaseShift = (diff / 135.0) * (1.0 + get_value(player, "tornadoZPeriod"))
		var returnReceptorToZeroOffsetX = (-sin(-columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt
		var offsetX = (-sin(phaseShift - columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt - returnReceptorToZeroOffsetX
		pos.z += offsetX * tornadoZVal

	# tornadoTanZ
	var tornadoTanZVal = get_value(player, "tornadoTanZ")
	if tornadoTanZVal != 0.0:
		var playerColumn = direction % key_count
		var columnPhaseShift = (playerColumn * PI_THIRD) + get_value(player, "tornadoTanZOffset") + PI
		var phaseShift = (diff / 135.0) * (1.0 + get_value(player, "tornadoTanZPeriod"))
		var returnReceptorToZeroOffsetX = (-sin(-columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt
		var offsetX = (-tan(phaseShift - columnPhaseShift) + 1.0) * HALF_WIDTH * key_cunt - returnReceptorToZeroOffsetX
		pos.z += offsetX * tornadoTanZVal

	# OpenITG/NotITG Tornado
	var itgTornadoVal = get_value(player, "itgTornado")
	var itgTornadoTanVal = get_value(player, "itgTornadoTan")
	if itgTornadoVal != 0.0 or itgTornadoTanVal != 0.0:
		var wide = key_count > 4
		var width = 2 if wide else 3
		var startColumn:int = int(clamp(direction - width, 0, key_count - 1))
		var endColumn:int = int(clamp(direction + width, 0, key_count - 1))

		var minX = startColumn * SWAG_WIDTH
		var maxX = endColumn * SWAG_WIDTH
		var realPixel = direction * SWAG_WIDTH

		var posBetween = scale_value(realPixel, minX, maxX, -1.0, 1.0)

		if itgTornadoVal != 0.0:
			var rads = acos(posBetween)
			var period = get_value(player, "itgTornadoPeriod")
			var offset = get_value(player, "itgTornadoOffset")
			rads += (diff + offset) * (6.0 + period * 6.0) / SCREEN_HEIGHT
			var adjusted = scale_value(cos(rads), -1.0, 1.0, minX, maxX)
			pos.x += (adjusted - realPixel) * itgTornadoVal

		if itgTornadoTanVal != 0.0:
			var rads = acos(posBetween)
			var period = get_value(player, "itgTornadoTanPeriod")
			var offset = get_value(player, "itgTornadoTanOffset")
			rads += (diff + offset) * (6.0 + period * 6.0) / SCREEN_HEIGHT
			var adjusted = scale_value(tan(rads), -1.0, 1.0, minX, maxX)
			pos.x += (adjusted - realPixel) * itgTornadoTanVal

	# digital
	var digitalVal = get_value(player, "digital")
	if digitalVal > 0.0:
		var steps = get_value(player, "digitalSteps") + 1.0
		var period = get_value(player, "digitalPeriod")
		var offset = get_value(player, "digitalOffset")
		pos.x += (digitalVal * HALF_WIDTH) * floor(0.5 + (steps * sin(get_digital_angle(diff, offset, period)))) / steps

	# digitalZ
	var digitalZVal = get_value(player, "digitalZ")
	if digitalZVal > 0.0:
		var steps = get_value(player, "digitalZSteps") + 1.0
		var period = get_value(player, "digitalZPeriod")
		var offset = get_value(player, "digitalZOffset")
		pos.z += (digitalZVal * HALF_WIDTH) * floor(0.5 + (steps * sin(get_digital_angle(diff, offset, period)))) / steps

	return pos
