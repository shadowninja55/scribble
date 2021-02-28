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
	redraw bool = true
}

fn on_frame(mut app App) {
	if app.dragging {
		if app.y < app.height && app.x < app.width {
			app.pixels[app.y][app.x] = true
		}
	}
	
	if !app.redraw { return }

	app.tui.clear()
	app.tui.set_bg_color(r: 255 g: 255 b: 255)

	for y, row in app.pixels {
		for x, pixel in row {
			if pixel {
				mut x_ := if x & 1 == 0 { x - 1 } else { x }
				app.tui.set_cursor_position(x_, y)
				app.tui.write("  ")
			}
		}
	}

	app.tui.reset()
	app.tui.flush()
}

fn on_event(event &ui.Event, mut app App) {
	app.redraw = false

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

			if app.dragging {
				app.redraw = true
			}
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
    frame_rate: 60
    hide_cursor: true
    window_title: "scribble"
  )

	app.pixels = [][]bool { len: app.height, init: []bool { len: app.width } }
  app.tui.run()?
}

