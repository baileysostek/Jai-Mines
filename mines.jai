#import "Basic";
#import "Math";
#import "Random";
#import "Window_Creation";
#import "Input";
#import "String";
#import "System";

// Window size and mouse pos.
#import "GetRect"; 

// Import Simp and resources
Simp    :: #import "Simp";
Texture :: Simp.Texture;

// Define our fonts to use with Simp
font: *Simp.Dynamic_Font;

// Game variables
should_quit_game := false;

window_width  :: 512;
window_height :: 512;
window : Window_Type;

// The states that the game can be in
GameState :: enum u8 {
  PLAY :: 0;
  GAME_OVER :: 1;
}

// Define the states our grid can be in.
GridState :: enum u8 {
  // These are non-numeric states
  UNOPENED  :: 0;
  FLAGGED   :: 1;
  REVEALED  :: 2;
}

// Moving from enum array to struct array
GridCell :: struct {
  state : GridState = GridState.UNOPENED;
  neighbors : u8 = 0;
  is_mine: bool = false;
}

// Set the sizes for width and height
WIDTH  : u8 : 16; // Here we do : instead of = to make an immutable constant.
HEIGHT : u8 : 16;

// This is not constant so as the window changes size later we can resize.
CELL_WIDTH  :: window_width / WIDTH;
CELL_HEIGHT :: window_height / HEIGHT;

// Define how many mines will be placed on our minefield
MINE_COUNT : u8 : 40;

//TODO strange... maybe bug. here we need to cast 
BOARD_SIZE : u16 : cast(u16)WIDTH * cast(u16)HEIGHT; // Auto Constant

// Deinfe our grid, this overlays our minefield and the player intreacts with it.
minefield : [BOARD_SIZE] GridCell; // The grid is the same size as the minefield.

main :: () {
  // Ensure that we never have more mines to place on the minefield, than minefield space available.
  assert((MINE_COUNT - 1) <= BOARD_SIZE); // The -1 here is because the first click will alwauys NOT be a mine.

  // Init stuff
  init_fonts();

  // Reset our minefield
  reset_game();

  // Create a new window and set it as Simp's render target.
  window = create_window(window_name="Jai-Mines", width=window_width, height=window_height);
  Simp.set_render_target(window);

  while !should_quit_game {
    reset_temporary_storage();
    
    Simp.clear_render_target(.2, .3, .3, 1);

    update_window_events();

    frame_logic();

    draw_board();
    message_width := Simp.prepare_text(font, "Click to Start Game");
    Simp.draw_prepared_text(font, xx (window_width - message_width) / 2, xx window_height / 2, Vector4.{.7, .7, .7, 1});

    Simp.swap_buffers(window);

    memory_visualizer_per_frame_update();
  }
}

frame_logic :: () {
  // get the mouse position
  mouse_x, mouse_y := get_mouse_pointer_position(window, true);

  // Event loop.
  for event : events_this_frame {
    if event.type == .QUIT {
      should_quit_game = true;
      break;
    }

    if event.key_code == .ESCAPE {
      if event.key_pressed should_quit_game = true;
      break;
    }

    if event.key_code == 82 {
      reset_game();
      break;
    }


    if event.key_code == .MOUSE_BUTTON_LEFT {
      if(event.key_pressed){
        // Reveal mines below us.
        print(ifx is_mouse_on_screen(mouse_x, mouse_y) then "Mouse on screen\n" else "Mouse off screen\n");

        cell_x : u8 = cast(u8) (mouse_x / (window_width / WIDTH));
        cell_y : u8 = cast(u8) (mouse_y / (window_height / HEIGHT));

        print("%,%\n", cell_x, cell_y);

        reveal_cell(get_index_from_xy(cell_x, cell_y));

        break;
      }
    }

    if event.key_code == .MOUSE_BUTTON_RIGHT {
      if(event.key_pressed){
        // Reveal mines below us.
        print(ifx is_mouse_on_screen(mouse_x, mouse_y) then "Mouse on screen\n" else "Mouse off screen\n");

        cell_x : u8 = cast(u8) (mouse_x / (window_width / WIDTH));
        cell_y : u8 = cast(u8) (mouse_y / (window_height / HEIGHT));

        toggle_flag(get_index_from_xy(cell_x, cell_y));

        break;
      }
    }
  }
  // print("mouse:%,%\n", mouse_x, mouse_y);
}

draw_board :: () {
  for item, index : minefield {

    x_pos := cast(float) (index % WIDTH);
    y_pos := floor(cast(float)index / cast(float)WIDTH);

    // If this cell is revealed
    if (item.state == GridState.UNOPENED) {
      continue;
    }

    Simp.set_shader_for_color(true);
    pos : Vector2 = .{x_pos * CELL_WIDTH, y_pos * CELL_HEIGHT};

    // // Draw the Grid itself
    if(item.state == GridState.FLAGGED){
      Simp.immediate_quad(pos.x, pos.y, pos.x + CELL_WIDTH, pos.y + CELL_HEIGHT,.{0, 0, 1, 1});
    } else {
      Simp.immediate_quad(pos.x, pos.y, pos.x + CELL_WIDTH, pos.y + CELL_HEIGHT, ifx check_mine(cast(u8)index) then Vector4.{1, 0, 0, 1} else .{0, 1, 0, 1});
      
      // Draw the number
      if(!item.is_mine){
        // There must be a better way to append an integer to a string.
        builder: String_Builder;
        init_string_builder(*builder);
        print_to_builder(*builder, "%", item.neighbors);
        neighbors_string := builder_to_string(*builder);

        Simp.prepare_text(font, neighbors_string);
        Simp.draw_prepared_text(font, xx pos.x + (CELL_WIDTH / 4), xx pos.y + (CELL_HEIGHT / 4), Vector4.{item.neighbors / 8.0, 0, 0, 1});
      }
    }
  }
}

reset_game :: () {
  // Reset random
  random_seed(current_time_monotonic().low);

  // print("Time is now %.\n", );

  // Reset the minefield and grid.
  for item, index : minefield {
    minefield[index] = GridCell.{
      GridState.UNOPENED,
      0,
      false
    };
  }

  // Place our mines
  to_place := MINE_COUNT;
  while to_place > 0 {
    pos : u8 = cast(u8) floor(random_get_zero_to_one() * BOARD_SIZE); 
    // Ensure that we are placing on a non-mine space.
    if(!check_mine(pos)){
      place_mine(pos);
      to_place -= 1;
    }
  }

  // Calculate the neighbors of each cell
  for item, index : minefield {
    minefield[index].neighbors = calculate_neighbors(cast(u8)index);
  }
}

check_flag :: (index : u16) -> bool {
  return minefield[index].state == GridState.FLAGGED;
}

check_mine :: (index : u16) -> bool {
  return minefield[index].is_mine;
}

place_mine :: (index : u16){
 minefield[index].is_mine = true;
}

calculate_neighbors :: (index : u16) -> u8 {
  pos_x, pos_y := get_xy_from_index(index);

  count : u8 = 0;

  for index_y : -1 .. 1{
    for index_x : -1 .. 1{
      
      evaluate_x := pos_x + index_x;
      evaluate_y := pos_y + index_y;

      if(is_point_on_grid(evaluate_x, evaluate_y) && check_mine(get_index_from_xy(cast(u8)evaluate_x, cast(u8)evaluate_y))){
        count += 1;
      }
    }
  }

  return count;
}

toggle_flag :: (index : u16){
  if(minefield[index].state != GridState.REVEALED){
    minefield[index].state = ifx minefield[index].state == GridState.FLAGGED then GridState.UNOPENED else GridState.FLAGGED;
  }
}

reveal_cell :: (index : u16){
  // If it is already revealed, do nothing
  if minefield[index].state != GridState.UNOPENED {
    return;
  }

  // Reveal this cell 
  print("Revaling:%\n", index);
  minefield[index].state = GridState.REVEALED;

  // If we click on a cell with no neighbors, reveal the neighbors
  if ( minefield[index].neighbors == 0 ) {

    pos_x, pos_y := get_xy_from_index(index);

    for index_y : -1 .. 1{
      for index_x : -1 .. 1{
        
        evaluate_x := pos_x + index_x;
        evaluate_y := pos_y + index_y;

        if is_point_on_grid(evaluate_x, evaluate_y) {
          neighbor_index := get_index_from_xy(cast(u8)evaluate_x, cast(u8)evaluate_y);
          reveal_cell(neighbor_index);
        }
      }
    }
  }
}

is_point_on_grid :: (pos_x:int, pos_y:int) -> bool {
  return (pos_x >= 0 && pos_x < WIDTH) && (pos_y >= 0 && pos_y < HEIGHT);
}

get_xy_from_index :: (index : u16) -> x:u8, y:u8 {
  return cast(u8)(index % WIDTH), cast(u8)floor((cast(float)index / cast(float)WIDTH));
}

get_index_from_xy :: (pos_x : u8, pos_y : u8) -> u16 {
  return pos_x + (pos_y * WIDTH);
}

is_mouse_on_screen  :: (mouse_x : int, mouse_y : int) -> bool {
  return mouse_x >= 0 && mouse_x < window_width && mouse_y >= 0 && mouse_y < window_height;
}

// "Borrowed" from the invaders example
render_sprite_quad_centered :: (texture: *Texture, _pos: Vector2, size: Vector2, color: Vector4) {
  Simp.set_shader_for_images(texture);
  
  pos := _pos * cast(float) window_width;
  h := make_vector2(size.x*.5*window_width, 0);
  v := make_vector2(0, size.y*.5*window_width);

  p0 := pos - h - v;
  p1 := pos + h - v;
  p2 := pos + h + v;
  p3 := pos - h + v;

  Simp.immediate_quad(p0, p1, p2, p3,  color);
}

init_fonts :: () {
  // So that we can load our font, set to path of running executable.
  // @Incomplete: Pack a default font into Simp.
  path := path_strip_filename(get_path_of_running_executable());

  set_working_directory(path);
  pixel_height := window_height / 24;

  // @Cleanup: Don't have path + name be separate.
  font = Simp.get_font_at_size("data", "Roboto-Regular.ttf", pixel_height);
  assert(font != null);
}
