express = require 'express'
fs = require 'fs'
coffee = require 'coffee-script'

app = module.exports = express.createServer()
app.configure ->
  app.use express.static("#{__dirname}/public")

app.get '/', (req, res) ->
  fs.readFile "#{__dirname}/index.html", 'utf8', (err, text) ->
    res.contentType 'text/html'
    res.send text

app.get '/test', (req, res) ->
  fs.readFile "#{__dirname}/test.html", 'utf8', (err, text) ->
    res.contentType 'text/html'
    res.send text

filenames = ['legs', 'simulation']
for filename in filenames
  do (filename) ->
    app.get "/#{filename}.js", (req, res) ->
      fs.readFile "#{__dirname}/#{filename}.coffee", 'utf8', (err, text) ->
        res.contentType 'application/javascript'
        res.send coffee.compile(text)

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"