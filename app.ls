require! <[ express ./routes/api ]>
port = process.env.PORT || 3000
app = express!


app.use '/', api


app.listen port, -> console.log "Server Listen on #{port}"