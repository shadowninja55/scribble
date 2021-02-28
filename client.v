import term.ui

struct App {
	width int = 200
	height int = 100
mut:
	tui &ui.Context = 0
	pixels [][]bool
	x int
	y int
	dragging bool
}

fn on_frame(mut app App) {
	app.tui.clear()
	app.tui.reset()

	if app.dragging {
		if app.y < app.height && app.x < app.width {
			app.pixels[app.y][app.x] = true
		}
	}

	for y, row in app.pixels {
		for x, pixel in row {
			if pixel {
				app.tui.set_cursor_position(x, y)
				app.tui.set_bg_color(r: 255 g: 255 b: 255)
				app.tui.write("  ")
				app.tui.reset()
			}
		}
	}

	app.tui.flush()
}

fn on_event(event &ui.Event, mut app App) {
	match event.typ {
		.mouse_down {
			app.dragging = true
		}
		.mouse_up {
			app.dragging = false
		}
		.mouse_move, .mouse_drag {
			app.x = event.x
			app.y = event.y
		}
		else {}
	}
}

fn main() {
  mut app := &App {}

  app.tui = ui.init(
    user_data: app
    frame_fn: on_frame
    event_fn: on_event
    frame_rate: 30
    hide_cursor: true
    window_title: "scribble"
  )

	app.pixels = [][]bool { len: app.height, init: []bool { len: app.width } }
  app.tui.run()?
}

