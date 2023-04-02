extends Node

# a new pin is created at position "where"
signal new_default_pin()

# the background image changed dimensions : here are the new ones
signal background_image_dimensions_changed(new_dim : Vector2)

# a new background is here !
signal changed_background_texture(new_texture : Texture2D)

# a pin is currently being hovered by the mouse.
signal pin_hover(pin : Node2D, entered : bool)

# deselect all pins
signal pin_request_all_deselection()

# a pin is deselected and closing its associated note
signal pin_deselected(pin : Node2D)
