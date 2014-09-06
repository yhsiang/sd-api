{ Router } = require 'express'

require! <[ request cheerio ]>

Api = Router!

Api.route '/news'
  .get (req, res) ->
    {page} = req.query
    items = []
    error, response, body <- request "http://taipeihope.tw/news.html?start=#{page * 9}"
    items ++= getItems body
    pages = getPages(body)

    res.json do
      items: items
      page: pages

getPages = (body) ->
  $ = cheerio.load body
  $ '.pagination' .children!first!text!match /共 (\d) 頁/ .1

getItems = (body) ->
  $ = cheerio.load body
  items = $ '.thum-box > a' .map (,it) ->
    do
      link: $ it .attr 'href'
      img-src: $ it .children!attr 'src'
      caption: $ it .children!attr 'alt' .trim!
      intro-text: $ it .parent!children!children!next!children!text!trim!
  items .= to-array!

module.exports = Api