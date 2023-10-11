class_name PinAppearance 
extends Node2D

## PinAppearance aggregates what nodes make a pin show the way it is.
##
## This is a just collection of Sprites.

## The icon texture is the topmost one.
@export var icon_texture : Texture2D :
	get: return $SpriteIcon.texture
	set(new_texture): 
		$SpriteIcon.texture = new_texture
		$SpriteIcon.scale = $SpriteBase.texture.get_size() / new_texture.get_size()


## Returns the size, in pixels, of the diameter of the base sprite.
func get_size_px() -> Vector2:
	return $SpriteBase.texture.get_size()


func hash_of_sprites() -> int:
	return [$SpriteBase, $SpriteRing, $SpriteIcon].hash()
