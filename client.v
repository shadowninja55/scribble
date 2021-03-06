import term.ui
import x.json2
import net
import os

struct Pos {
mut:
	x int
	y int
}

struct App {
mut:
	tui      &ui.Context = 0
	curr     Pos
	last     Pos
	selected int
	dragging bool
	erasing  bool
	conn     &net.TcpConn = 0
	drawing  bool
	name     string
	points   int
	chat     []string
	text     string
}

const (
	canvas_width  = 100
	canvas_height = 25
	chat_width    = 50
	colors        = [
		ui.Color{
			r: 255
		} /* red */,
		ui.Color{
			r: 255
			g: 127
		} /* orange */,
		ui.Color{
			r: 255
			g: 255
		} /* yellow */,
		ui.Color{
			r: 127
			g: 255
		} /* chartreuse */,
		ui.Color{
			g: 255
		} /* lime */,
		ui.Color{
			g: 255
			b: 127
		} /* emerald */,
		ui.Color{
			g: 255
			b: 255
		} /* cyan */,
		ui.Color{
			g: 127
			b: 255
		} /* azure */,
		ui.Color{
			b: 255
		} /* blue */,
		ui.Color{
			b: 255
			r: 127
		} /* violet */,
		ui.Color{
			b: 255
			r: 255
		} /* magenta */,
		ui.Color{
			b: 127
			r: 255
		} /* rose */,
	]
	bg_color      = ui.Color{
		r: 255
		g: 255
		b: 255
	}
)

fn on_init(mut app App) {
	app.tui.set_bg_color(bg_color)
	app.tui.draw_rect(chat_width, 1, chat_width + app.tui.window_width, canvas_height)
	app.draw_name()
	app.tui.draw_text(1, canvas_height + 1, '> ')
	draw_palette(mut app.tui, app.selected)
	app.tui.flush()
}

fn on_frame(mut app App) {
	app.draw_name()
	msg := app.conn.read_line()
	app.draw_chat()
	app.tui.draw_text(3, canvas_height + 1, app.text.len.str())
	if !app.erasing {
		app.tui.set_bg_color(colors[app.selected])
		draw_palette(mut app.tui, app.selected)
	}
	if app.drawing {
		if msg != '' {
			dec := json2.raw_decode(msg) or { panic('decode error: $err') }
			m := dec.as_map()
			match m['type'].str() {
				'chat' {
					app.chat << m['sender'].str() + ': ' + m['message'].str()
				}
				else {}
			}
		}
		if !app.dragging && !app.erasing {
			app.last = {}
		}

		if app.last.x != 0 && app.last.y != 0 {
			if app.curr.x <= canvas_width + chat_width && app.curr.x >= chat_width
				&& app.curr.y <= canvas_height && app.last.x <= canvas_width + chat_width
				&& app.last.x >= chat_width && app.last.y <= canvas_height {
				app.conn.write_str('{"type": "line", "curr": {"x": $app.curr.x, "y": $app.curr.y}, "last": {"x": $app.last.x, "y": $app.last.y}}') or {
					panic(err)
				}
				draw_line(mut app.tui, app.last, app.curr)
			}
		}

		app.last = app.curr
	} else {
		if msg != '' {
			dec := json2.raw_decode(msg) or { panic('decode error: $err') }
			m := dec.as_map()
			match m['type'].str() {
				'line' {
					c := m['curr'].as_map()
					l := m['last'].as_map()
					curr := Pos{
						x: c['x'].int()
						y: c['y'].int()
					}
					last := Pos{
						x: l['x'].int()
						y: l['y'].int()
					}
					draw_line(mut app.tui, last, curr)
				}
				'select' {
					app.selected = m['col'].int()
					draw_palette(mut app.tui, app.selected)
				}
				'erase' {
					app.erasing = m['erasing'].bool()
				}
				'chat' {
					app.chat << m['sender'].str() + ': ' + m['message'].str()
				}
				else {}
			}
		}
	}
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
					app.conn.write_str('{"type": "erase", "erasing": true}') or { panic(err) }
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
					app.conn.write_str('{"type": "erase", "erasing": false}') or { panic(err) }
				}
				else {}
			}
		}
		.mouse_move, .mouse_drag {
			app.curr.x = event.x
			app.curr.y = event.y
		}
		.mouse_scroll {
			if !app.drawing {
				return
			}

			match event.direction {
				.up {
					app.selected++

					if app.selected >= colors.len {
						app.selected = 0
					}
					app.conn.write_str('{"type": "select", "col": $app.selected}') or { panic(err) }
				}
				.down {
					app.selected--

					if app.selected < 0 {
						app.selected = colors.len - 1
					}
					app.conn.write_str('{"type": "select", "col": $app.selected}') or { panic(err) }
				}
				else {}
			}
		}
		.key_down {
			match event.code {
				.backspace {
					app.text = app.text[..(app.text.len - 1)]
					app.tui.draw_line(3, canvas_height + 1, app.text.len + 3, canvas_height + 1)
				}
				else {}
			}
			match event.utf8 {
				'\n' {
					app.tui.set_bg_color(bg_color)
					app.tui.draw_line(3, canvas_height + 1, app.text.len + 3, canvas_height + 1)
					app.conn.write_str('{"type": "chat", "message": "$app.text", "sender": "$app.name"}') or {
						panic(err)
					}
					app.text = ''
				}
				else {
					app.text += event.utf8
				}
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
	app.conn = net.dial_tcp('127.0.0.1:6969') ?
	name := os.input('choose a name: ')
	app.name = name
	app.conn.write_str('{"type": "join", "name": "$name"}') ?
	app.drawing = os.input('e: ').bool()
	app.tui.run() ?
}

pub fn draw_line(mut ctx ui.Context, p1 Pos, p2 Pos) {
	mut x0, x1 := p1.x, p2.x
	mut y0, y1 := p1.y, p2.y
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	dx := if x0 < x1 { x1 - x0 } else { x0 - x1 }
	dy := if y0 < y1 { y0 - y1 } else { y1 - y0 }
	mut err := dx + dy
	for {
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

pub fn draw_palette(mut ctx ui.Context, selected int) {
	// drawing out colors
	for idx in 0 .. colors.len {
		x := chat_width + 1 + idx * 2

		ctx.set_bg_color(colors[idx])
		ctx.draw_point(x, canvas_height + 1)
		ctx.draw_point(x + 1, canvas_height + 1)
	}

	// drawing selected
	ctx.set_bg_color(colors[selected])
	ctx.set_color({})
	ctx.set_cursor_position(1 + chat_width + selected * 2, canvas_height + 1)
	ctx.write('><')
}

pub fn (mut app App) draw_name() {
	app.tui.set_bg_color(bg_color)
	app.tui.draw_text(canvas_width + 2 + chat_width, 1, '$app.name - $app.points')
}

pub fn (mut app App) draw_chat() {
	app.tui.draw_rect(1, 1, chat_width, canvas_height)
	for index, msg in app.chat {
		app.tui.draw_text(1, canvas_height - app.chat.len + index, msg)
	}
}
