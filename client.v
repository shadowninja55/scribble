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
	selector int
	dragging bool
	erasing bool
}

const ( 
	colors = [
		ui.Color { r: 255 }, // red
		ui.Color { r: 255 g: 127 }, // orange
		ui.Color { r: 255 g: 255 }, // yellow
		ui.Color { r: 127 g: 255 }, // chartreuse
		ui.Color { g: 255 }, // lime
		ui.Color { g: 255 b: 127 }, // emerald
		ui.Color { g: 255 b: 255 }, // cyan
		ui.Color { g: 127 b: 255 }, // azure
		ui.Color { b: 255 }, // blue
		ui.Color { b: 255 r: 127 }, // violet
		ui.Color { b: 255 r: 255 }, // magenta
		ui.Color { b: 127 r: 255 } // rose
	]

	bg_color = ui.Color { r: 255 g: 255 b: 255 }
)

fn on_init(mut app App) {
	app.tui.set_bg_color(bg_color)
	app.tui.draw_rect(1, 1, app.width, app.height + 1)
	app.tui.flush()
}

fn on_frame(mut app App) {
	if !app.dragging && !app.erasing {
		app.last = {}
	}

	if !app.erasing {
		app.tui.set_bg_color(colors[app.selector])
	  app.tui.draw_point(1, 1)
		app.tui.draw_point(2, 1)
	} else {
		app.tui.set_bg_color(bg_color)
	}
	
	if app.last.x != 0 && app.last.y != 0 {
		draw_line(mut app.tui, app.last, app.curr)
	}

	app.last = app.curr
	app.tui.flush()
}

fn on_event(event &ui.Event, mut app App) {
	match event.typ {
		.mouse_down {
			match event.button {
				.left {
					app.dragging = true
				}
				.right {
					app.erasing = true
				}
				else {}
			}
		}
		.mouse_up {
			match event.button {
				.left {
					app.dragging = false
				}
				.right {
					app.erasing = false
				}
				else {}
			}
		}
		.mouse_move, .mouse_drag {
			app.curr.x = event.x
			app.curr.y = event.y
		}
		.mouse_scroll {
			match event.direction {
				.up {
					app.selector++

					if app.selector >= colors.len {
						app.selector = 0
					}
				}
				.down {
					app.selector--

					if app.selector < 0 {
						app.selector = colors.len - 1
					}
				}
				else {}
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
		init_fn: on_init
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
