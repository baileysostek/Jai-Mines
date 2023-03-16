#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
// Math Matrices are row-major. In other words,
// you have [row 0][row 1][row 2][...] in memory.
#import "Math";
#import "File";
#import "File_Utilities";
#import "System";
#import "GL";
#import "Hash_Table";

simp :: #import "Simp";
getrect :: #import "GetRect";

g_current_window_width, g_current_window_height : s32;
g_window : Window_Type;
g_running : bool;
g_control_camera : bool;

handle_window_event :: (event : Event)
{
	getrect.getrect_handle_event (event);
	if event.type ==
	{
	case .QUIT;
		g_running = false;
	case .KEYBOARD;
		if event.key_pressed
		{
			if event.key_code == .ESCAPE
				set_camera_control (!g_control_camera);
			if event.key_code == .F4 && event.alt_pressed
				g_running = false;
		}
	}
}

set_camera_control :: inline (control : bool)
{
	g_control_camera = control;
	if g_control_camera
		hide_cursor ();
	else
		show_cursor ();
}

main :: ()
{
	// This is here because on Windows, segfaults and stuff are silent.
	// If the program ends without printing this message, then something bad happened.
	defer print ("Program ended gracefully.\n");

	#if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.SetProcessDPIAware ();
	}

	g_window = create_window (1280, 720, "Skeletal Animation");
	simp.set_render_target (g_window);

  g_running = true;
  delta_time := 0.01667;

  while g_running {
    frame_start := current_time_monotonic ();
		reset_temporary_storage ();
		update_window_events ();
		for get_window_resizes ()
		{
			if it.window == g_window
			&& ((g_current_window_width != it.width) || (g_current_window_height != it.height))
			{
				g_current_window_width = it.width;
				g_current_window_height = it.height;
				// reinit_fonts ();	// We want the fonts to scale with the window
			}
		}
		for events_this_frame
			handle_window_event (it);

		update_frame (delta_time);

		glDepthMask (GL_TRUE);
		glEnable (GL_DEPTH_TEST);
		simp.update_window (g_window);
		simp.clear_render_target (0.1, 0.1, 0.1, 1);
		glClear (GL_DEPTH_BUFFER_BIT);
		// if g_mesh && g_params.show_mesh
		// 	draw_mesh (g_mesh, Matrix4_Identity, g_pose.skinning_matrices);
		// Draw coordinate axes
		// draw_line (.{}, .{x=1}, .{x=1, w=1});
		// draw_line (.{}, .{y=1}, .{y=1, w=1});
		// draw_line (.{}, .{z=1}, .{z=1, w=1});
		// // Draw grid
		// for i : -10..10
		// 	draw_line (xyz (xx i, 0, -10), xyz (xx i, 0, 10), .{0.4, 0.4, 0.4, 1});
		// for i : -10..10
		// 	draw_line (xyz (-10, 0, xx i), xyz (10, 0, xx i), .{0.4, 0.4, 0.4, 1});

		// if g_mesh && g_params.show_skeleton
		// {
		// 	// Disable depth mask and testing so we can see
		// 	// the skeleton through other things
		// 	glDepthMask (GL_FALSE);
		// 	glDisable (GL_DEPTH_TEST);
		// 	draw_pose (g_pose, Matrix4_Identity, xyzw (g_params.skeleton_color, 1));
		// }

		// update_ui (delta_time);

		simp.swap_buffers (g_window);
		sleep_milliseconds (10);
		frame_end := current_time_monotonic ();
		delta_time = cast (float) to_float64_seconds (frame_end - frame_start);
  }
}

update_frame :: (delta_time : float) {
  
}

is_key_down :: inline (key : Key_Code) -> bool #must
{
	return (input_button_states[cast (s64) key] & .DOWN) != 0;
}

show_cursor :: inline ()
{
	#if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.ShowCursor (1);
	}
	else
	{
		// @Todo!
	}
}

hide_cursor :: inline ()
{
	#if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.ShowCursor (0);
	}
	else
	{
		// @Todo!
	}
}