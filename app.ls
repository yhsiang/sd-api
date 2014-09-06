require! <[ express ./routes/api ]>
port = 3000
app = express!


app.use '/', api


app.listen port, -> console.log "Server Listen on #{port}"