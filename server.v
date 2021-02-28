import net
import os

struct Server {
mut:
	listener net.TcpListener
	clients  []Client
}

struct Client {
	id int
mut:
	conn net.TcpConn
}

fn (mut server Server) handle_conn(conn &net.TcpConn) {
	mut client := Client{
		id: server.clients.len
		conn: conn
	}
	server.clients << client
	for {
		line := client.conn.read_line()
		for mut receiver in server.clients {
			receiver.conn.write_str(line) or { continue }
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
