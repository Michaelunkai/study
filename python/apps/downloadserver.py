from http.server import SimpleHTTPRequestHandler, HTTPServer
import os

class CustomRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/mnt/c':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Path /mnt/c is being broadcasted.")
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/upload':
            content_type = self.headers['Content-Type']
            if 'multipart/form-data' in content_type:
                form_data = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={'REQUEST_METHOD': 'POST',
                             'CONTENT_TYPE': self.headers['Content-Type']}
                )
                uploaded_file = form_data['file'].file.read()

                # Specify the directory where you want to save the uploaded file
                upload_dir = '/path/to/upload/directory'
                
                # You can change the file name if needed
                filename = os.path.join(upload_dir, form_data['file'].filename)

                with open(filename, 'wb') as f:
                    f.write(uploaded_file)

                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'File uploaded successfully.')
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid request. Only multipart/form-data POST requests are supported.')
        else:
            super().do_POST()

    def get_upload_form(self):
        upload_form = '''
        <html>
        <body>
            <form action="/upload" method="post" enctype="multipart/form-data">
                <input type="file" name="file">
                <input type="submit" value="Upload">
            </form>
        </body>
        </html>
        '''
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(upload_form.encode())

def run_server():
    server_address = ('', 8000)  # You can change the port if needed
    httpd = HTTPServer(server_address, CustomRequestHandler)
    print('Server is running...')
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()

