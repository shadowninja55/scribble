import net
import os
import x.json2

struct App {
	word   string
	client int
}

struct Server {
mut:
	listener net.TcpListener
	clients  []Client
}

struct Client {
	id int
mut:
	connected bool
	name      string
	conn      net.TcpConn
}

fn (mut server Server) handle_conn(conn &net.TcpConn) {
	mut client := Client{
		id: server.clients.len
		conn: conn
	}
	server.clients << client
	for {
		line := client.conn.read_line()
		if line != '' {
			println(line)
			msg := json2.raw_decode(line) or { continue }
			content := msg.as_map()
			match content['type'].str() {
				'line' {}
				'word' {}
				'join' {
					server.clients[client.id].name = content['name'].str()
					println(content['name'].str() + ' joined!')
				}
				'leave' {
					server.clients[client.id].connected = false
				}
				else {}
			}
			for mut receiver in server.clients {
				receiver.conn.write_str(line) or { continue }
			}
		}
	}
}

fn main() {
	mut port := 6969
	mut listener := net.listen_tcp(port) ?
	mut server := &Server{
		listener: listener
	}
	for {
		conn := server.listener.accept() or { continue }
		go server.handle_conn(conn)
	}
}
