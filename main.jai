#import "Basic";
#import "Math";
#import "Random";
#import "Window_Creation";
#import "Input";

// Import Simp and resources
Simp    :: #import "Simp";
Texture :: Simp.Texture;

// Game variables
should_quit_game := false;

// Define the states our minefield cells can be in.
CellState :: enum u8 {
  EMPTY :: 0;
  MINE  :: 1;
}

// Define the states our grid can be in.
GridState :: enum u8 {
  // These states represent the number of neighbors
  ZERO      :: 0;
  ONE       :: 1;
  TOW       :: 2;
  THREE     :: 3;
  FOUR      :: 4;
  FIVE      :: 5;
  SIX       :: 6;
  SEVEN     :: 7;
  EIGHT     :: 8;

  // These are non-numeric states
  FLAGGED   :: 9;
  UNOPENED  :: 10;
}

// Set the sizes for width and height
WIDTH  : u8 : 16; // Here we do : instead of = to make an immutable constant.
HEIGHT : u8 : 16;

// Define how many mines will be placed on our minefield
MINE_COUNT : u8 : 40;

BOARD_SIZE :: WIDTH * HEIGHT; // Auto Constant

// Define our minefield
minefield : [BOARD_SIZE] CellState; // The members of an array are guarenteed to be initialized to the value of 0. Since this is an array of enums this represents the first entry of the enum.

// Deinfe our grid, this overlays our minefield and the player intreacts with it.
grid : [BOARD_SIZE] GridState; // The grid is the same size as the minefield.

main :: () {
  // Ensure that we never have more mines to place on the minefield, than minefield space available.
  assert((MINE_COUNT - 1) <= BOARD_SIZE); // The -1 here is because the first click will alwauys NOT be a mine.

  // Reset our minefield
  reset_game();

  // Open a simp window.
  width  := 512;
  height := 512;

  window := create_window(window_name="Jai-Mines", width=width, height=height);
  Simp.set_render_target(window);

  while !should_quit_game {
    reset_temporary_storage();
    
    Simp.clear_render_target(.2, .3, .3, 1);

    update_window_events();

    frame_logic();

    draw_board();

    Simp.swap_buffers(window);

    memory_visualizer_per_frame_update();
  }
}

frame_logic :: () {
  for event : events_this_frame {
    if event.type == .QUIT {
        should_quit_game = true;
        break;
    }

    if event.key_code == .ESCAPE 
        if event.key_pressed should_quit_game = true;
  }
}

reset_game :: () {
  // Reset the minefield and grid.
  for value, index : minefield {
    minefield[index] = CellState.EMPTY;
    grid[index] = GridState.UNOPENED;
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
  
  // Print the Minefield.
  print("%", minefield);
}


check_mine :: (index : u8) -> bool {
  return minefield[index] == CellState.MINE;
}

place_mine :: (index : u8){
 minefield[index] = CellState.MINE;
}

render :: () {

}

on_mouse_click :: () {

}