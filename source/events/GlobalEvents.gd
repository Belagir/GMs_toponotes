extends Node

# a new pin is created at position "where"
signal new_default_pin(current_zoom : Vector2)

# the background image changed dimensions : here are the new ones
signal background_image_dimensions_changed(old_dim : Vector2, new_dim : Vector2)

# a new background is here !
signal changed_background_texture(new_texture : Texture2D)

# a pin is currently being hovered by the mouse.
signal pin_hover(pin : Node2D, entered : bool)

# deselect all pins
signal pin_request_all_deselection()

# a pin is deselected and closing its associated note
signal pin_deselected(pin : Node2D)

# a new zoom level has been reached by the camera
signal zoom_level_changed(new_level : Vector2)

# some change was applied to the map
signal map_got_a_change()
