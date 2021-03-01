import term.ui

struct Pos {
mut:
	x int
	y int
}

struct App {
	width  int = 200
	height int = 100
mut:
	tui      &ui.Context = 0
	curr Pos
	last Pos
	dragging bool
	redraw   bool = true
}

fn on_frame(mut app App) {
	if !app.dragging {
		app.last = {}
	}
	if !app.redraw {
		return
	}

	app.tui.set_bg_color(r: 255, g: 255, b: 255)
	if app.last.x != 0 && app.last.y != 0 {
		draw_line(mut app.tui, app.last, app.curr)
	}
	app.last = app.curr

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
			app.curr.x = event.x
			app.curr.y = event.y

			if app.dragging {
				app.redraw = true
			}
		}
		else {}
	}
}

fn main() {
	mut app := &App{}

	app.tui = ui.init(
		user_data: app
		frame_fn: on_frame
		event_fn: on_event
		frame_rate: 60
		hide_cursor: true
		window_title: 'scribble'
	)
	app.tui.run() ?
}

pub fn draw_line(mut ctx ui.Context, p1 Pos, p2 Pos) {
  // Draw the various points with Bresenham's line algorithm:
	mut x0, x1 := p1.x, p2.x
	mut y0, y1 := p1.y, p2.y
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	dx := if x0 < x1 { x1 - x0 } else { x0 - x1 }
	dy := if y0 < y1 { y0 - y1 } else { y1 - y0 } // reversed
	mut err := dx + dy
	for {
		// res << Segment{ x0, y0 }
		x_ := if x0 & 1 == 0 { x0 - 1 } else { x0 }
		ctx.draw_point(x_, y0)
		ctx.draw_point(x_ + 1, y0)
		if x0 == x1 && y0 == y1 {
			break
		}
		e2 := 2 * err
		if e2 >= dy {
			err += dy
			x0 += sx
		}
		if e2 <= dx {
			err += dx
			y0 += sy
		}
	}
}
