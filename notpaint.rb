require 'tk'
require 'chunky_png'

class NotPaint
  def initialize
    @root = TkRoot.new { title "NotPaint" }  # Create main window

    @colors = { # Hash for brush colours
      'Black' => 'black',
      'Red' => 'red',
      'Green' => 'green',
      'Blue' => 'blue'
    }  

    @sizes = [1, 3, 5, 7]  # Array for brush sizes

    create_menu_bar  # Create the menu bar
    create_canvas  # Create the drawing canvas
    @current_color = @colors.values.first  # Set the initial color to the first color in the @colors hash
    @current_size = @sizes.first  # Set the initial brush size to the first size in the @sizes array
    bind_mouse_events  # Bind mouse events to the canvas

    Tk.mainloop  
  end

  private # To ensure methods cant be called from other file

  def create_menu_bar
    menu_bar = TkMenu.new(@root)  # Create a menu bar for the main window
    @root['menu'] = menu_bar  # Set the menu bar

    create_file_menu(menu_bar)  # Create the file menu
    create_color_menu(menu_bar)  # Create the color menu
    create_size_menu(menu_bar)  # Create the brush size menu
  end

  def create_file_menu(menu_bar)
    file_menu = TkMenu.new(menu_bar)  # Create a file menu
    menu_bar.add('cascade', menu: file_menu, label: 'File')  # Add the file menu to the menu bar

    file_menu.add('command', label: 'Open', command: method(:open_file))  # Add an "Open" option to the file menu
    file_menu.add('command', label: 'Save', command: method(:save_file))  # Add a "Save" option to the file menu
    file_menu.add('command', label: 'Exit', command: method(:exit))  # Add an "Exit" option to the file menu
  end

  def create_color_menu(menu_bar)
    color_menu = TkMenu.new(menu_bar)  # Create a color menu
    menu_bar.add('cascade', menu: color_menu, label: 'Color')  # Add the color menu to the menu bar

    @colors.each do |label, color|
      color_menu.add('command', label: label, command: -> { change_color(color) })  # Add color options
    end
  end

  def create_size_menu(menu_bar)
    size_menu = TkMenu.new(menu_bar)  # Create a brush size menu
    menu_bar.add('cascade', menu: size_menu, label: 'Brush Size')  # Add the brush size menu to the menu bar

    @sizes.each do |size|
      size_menu.add('command', label: size.to_s, command: -> { change_size(size) })# Add size options 
    end
  end

  def create_canvas
    @canvas = TkCanvas.new(@root) { background 'white' }  # Create canvas with white background
    @canvas.pack(fill: :both, expand: true)  # Make the canvas fill the available space
    @canvas.width = 1000  # initial width of canvas
    @canvas.height = 500  # initial height of canvas
  end

  def bind_mouse_events
    @canvas.bind("1", method(:start_drawing))  # Bind left mouse button click event to start_drawing
    @canvas.bind("B1-Motion", method(:continue_drawing))  # Bind mouse motion to the continue_drawing
    @canvas.bind("ButtonRelease-1", method(:stop_drawing))  # Bind left release to the stop_drawing
  end

  def start_drawing(event)
    @start_x = event.x  # Store the x-coordinate of the starting point
    @start_y = event.y  # Store the y-coordinate of the starting point
  end

  def continue_drawing(event)
    # Draw a line from the previous point to the current point on the canvas
    @canvas.create(:line, @start_x, @start_y, event.x, event.y, fill: @current_color, width: @current_size)
    @start_x = event.x  # Update the x-coordinate of the starting point
    @start_y = event.y  # Update the y-coordinate of the starting point
  end

  def stop_drawing
    @start_x = nil  # Reset the x-coordinate of the starting point
    @start_y = nil  # Reset the y-coordinate of the starting point
  end

  def save_file # Creates ps and converts to png
    file_path = Tk.getSaveFile(filetypes: [['PNG', '.png']], defaultextension: '.png')  # Show a save file dialog to get the file path
    return if file_path.nil? || file_path.empty?  # Return if the file path is not specified

    ps_file_path = "#{file_path}.ps"  # Create a PostScript file path
    @canvas.postscript(file: ps_file_path)  # Save the canvas as a PostScript file

    `convert #{ps_file_path} #{file_path}`  # Convert the PostScript file to PNG using ImageMagick convert

    File.delete(ps_file_path)  # Delete the PostScript file

    Tk.messageBox(title: 'Save', message: "Canvas saved as '#{file_path}'")  # Show message box to confirm saving
  end

  def open_file
    file_path = Tk.getOpenFile(filetypes: [['PNG', '.png']])  # Open explorer for file path
    return if file_path.nil? || file_path.empty?  # Return if the file path is not specified

    image = ChunkyPNG::Image.from_file(file_path)  # Read the PNG image file using ChunkyPNG
    width = image.width  # Get the width of the image
    height = image.height  # Get the height of the image

    @canvas.delete(:all)  # Clear canvas

    @canvas.width = width  # Set width of the canvas
    @canvas.height = height  # Set height of the canvas

    photo_image = create_photo_image(image, width, height)  # Create a Tk photo image from the ChunkyPNG image

    @canvas.create(:image, 0, 0, image: photo_image, anchor: 'nw')  # Add the photo image to the canvas

    @canvas.configure(scrollregion: [0, 0, width, height])  # Configure the scroll region of the canvas

    change_color(@colors.values.first)  # Set current brush colour to the first colour in the @colors hash
    change_size(@sizes.first)  # Set the current brush size to the first size in the @sizes array
  rescue StandardError => err
    puts "Error opening file: #{err.message}"  # Puts an error message
  end

  def create_photo_image(image, width, height)
    photo_image = TkPhotoImage.new(width: width, height: height)  # Create a Tk photo image with the specified dimensions

    (0...width).each do |x|
      (0...height).each do |y|
        color_value = image[x, y]  # Get the color value at the current pixel
        red = ChunkyPNG::Color.r(color_value)  # Get the red component of the color
        green = ChunkyPNG::Color.g(color_value)  # Get the green component of the color
        blue = ChunkyPNG::Color.b(color_value)  # Get the blue component of the color
        
        color_hex = sprintf("#%02x%02x%02x", red, green, blue)  # Convert the color components to a hex string
        photo_image.put(color_hex, to: [x, y])  # Set the color of the corresponding pixel in the photo image
      end
    end

    photo_image  # Return the created photo image
  end

  def change_color(color)
    @current_color = color  # Update the current color to the specified color
  end

  def change_size(size)
    @current_size = size  # Update the current brush size to the specified size
  end
end

NotPaint.new  