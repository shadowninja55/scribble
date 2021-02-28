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

	if app.dragging {
		app.pixels[app.y][app.x] = true
	}

	for y, row in app.pixels {
		for x, pixel in row {
			if pixel {
				app.tui.draw_rect(x, y, x + 1, y + 1)
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
		.mouse_move {
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

	app.pixels = [][]bool{ len: app.height, init: []bool{ len: app.width } }

  app.tui.run()?
}

