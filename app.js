const http = require('http');
var os = require("os");

const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(os.hostname());
});

server.listen(port, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
