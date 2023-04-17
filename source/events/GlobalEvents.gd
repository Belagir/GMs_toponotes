extends Node

# the background image changed dimensions : here are the new ones
signal changed_background_image_dimensions(old_dim : Vector2, new_dim : Vector2)

# some change was applied to the map
signal changed_something_on_the_map()

# a new zoom level has been reached by the camera
signal changed_zoom_level(new_level : Vector2)

# some object was brought to the yop z-level from the `from` value.
signal brought_pin_upward_z_level(from : int)

# a pin is hovered by the mouse
signal hovered_pin_by_mouse(pin : Pin, entered : bool)

# a new background is here and must be applied !
signal requested_change_of_background_image(new_texture : Texture2D)

# deselect all pins
signal requested_deselection_of_all_pins()

# a new pin is created at a certain position
signal requested_new_default_pin(where : Vector2)

# a new blank map is requested
signal requested_map_wipe()

# a pin changed state
signal switched_pin_state(pin : Pin, old_state : String, new_state : String)
