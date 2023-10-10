extends Node

## This is the definition of global signals that any class can connect to or
## emit.

## The background image changed dimensions : here are the new ones
signal changed_background_image_dimensions(old_dim : Vector2, new_dim : Vector2)

## Some change was applied to the map
signal changed_something_on_the_map()

## A new zoom level has been reached by the camera
signal changed_zoom_level(new_level : Vector2)

## Some object was brought to the yop z-level from the `from` value.
signal brought_pin_upward_z_level(from : int)

## A pin is being focused by the user
signal focused_pin(pin : Pin)

## A pin is hovered by the mouse
signal hovered_pin_by_mouse(pin : Pin, entered : bool)

## A new background is here and must be applied !
signal requested_change_of_background_image(new_texture : Texture2D)

## Deselect all pins
signal requested_deselection_of_all_pins(exceptions : Array[Pin])

## A new pin is created at a certain position
signal requested_new_default_pin(where : Vector2)

## A new blank map is requested
signal requested_map_wipe()

## A pin changed state
signal switched_pin_state(pin : Pin, old_state : String, new_state : String)

## pins' starting size has changed
signal changed_pins_starting_size(new_size : int)

## a pin changed appearance
signal changed_pin_appearance(pin_app : PinAppearance)

## a pin has been removed with this appearance
signal removed_pin_appearance(pin_app : PinAppearance)
