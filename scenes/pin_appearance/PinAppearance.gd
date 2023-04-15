class_name PinAppearance 
extends Node2D


@export var icon_texture : Texture2D :
	get: return $SpriteIcon.texture
	set(new_texture): 
		$SpriteIcon.texture = new_texture
		$SpriteIcon.scale = $SpriteBase.texture.get_size() / new_texture.get_size()


func get_size_px() -> Vector2:
	return $SpriteBase.texture.get_size()
