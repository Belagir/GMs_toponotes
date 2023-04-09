extends Node

# a new pin is created at position "where"
signal new_default_pin()

# the background image changed dimensions : here are the new ones
signal background_image_dimensions_changed(old_dim : Vector2, new_dim : Vector2)

# a new background is here and must be applied !
signal changed_background_texture(new_texture : Texture2D)

# a pin is currently being hovered by the mouse.
signal pin_hover(pin : Pin, entered : bool)

# a pin was selected
signal pin_selected(pin : Pin)

# some object was brought to the yop z-level from he mimit value.
signal bring_pins_z_level_down(limit : int)

# deselect all pins
signal pin_request_all_deselection()

# a pin is deselected and closing its associated note
signal pin_deselected(pin : Node2D)

# a new zoom level has been reached by the camera
signal zoom_level_changed(new_level : Vector2)

# some change was applied to the map
signal map_got_a_change()

# a new blank map is requested
signal request_map_wipe()
