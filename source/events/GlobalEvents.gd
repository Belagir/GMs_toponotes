extends Node

# a new pin is created at a certain position
signal requested_new_default_pin(where : Vector2)

# the background image changed dimensions : here are the new ones
signal changed_background_image_dimensions(old_dim : Vector2, new_dim : Vector2)

# a pin is hovered by the mouse
signal hovered_pin_by_mouse(pin : Pin, entered : bool)

# a new background is here and must be applied !
signal requested_change_of_background_image(new_texture : Texture2D)

# a pin changed state
signal switched_pin_state(pin : Pin, old_state : String, new_state : String)

# some object was brought to the yop z-level from he mimit value.
signal bring_pins_z_level_down(limit : int)

# deselect all pins
signal pin_request_all_deselection()

# a new zoom level has been reached by the camera
signal zoom_level_changed(new_level : Vector2)

# some change was applied to the map
signal map_got_a_change()

# a new blank map is requested
signal request_map_wipe()
