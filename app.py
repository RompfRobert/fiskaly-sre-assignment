from http.server import BaseHTTPRequestHandler, HTTPServer


class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Hello World")

    def log_message(self, format, *args):
        # Keep container logs clean for this simple exercise.
        return


def main():
    server = HTTPServer(("0.0.0.0", 8080), HelloHandler)
    print("Listening on 0.0.0.0:8080")
    server.serve_forever()


if __name__ == "__main__":
    main()
