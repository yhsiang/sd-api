{ Router } = require 'express'

require! <[ request cheerio ]>

Api = Router!

origin = 'http://taipeihope.tw'
host = process.env.HOST || 'http://localhost:3000'

Api.route '/'
  .get (req, res) ->
    res.json do
      is-success: false
      error-code: 404
      error-message: "no API found,for more detail,please reference to our docs. ( #{host}/docs/ )",
      data: null

Api.route '/news'
  .get (req, res) ->
    {page} = req.query
    items = []
    error, response, body <- request "http://taipeihope.tw/news.html?start=#{page * 9}"
    items ++= getItems body
    pages = getPages(body)

    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: items
      page-info:
        total-pages: pages
        results-per-page: 9

Api.route '/news/:id'
  .get (req, res) ->
    id = req.param 'id'
    error, response, body <- request "http://taipeihope.tw/news/blog/#{id}.html"

    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: [ getArticle body ]

Api.route '/videos'
  .get (req, res) ->
    error, response, body <- request "http://taipeihope.tw/gallery.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getVideos body


getVideos = (body) ->
  $ = cheerio.load body
  items = $ '.video-links > .col-md-4 > .intro-img > a' .map (,it) ->
    link = $ it .attr 'href'
    link = 'http:' + link if not link.match /^http/
    do
      link: link
      title: $ it .children!attr 'alt'
      img-src: $ it .children!attr 'src'
  items .= to-array!

getArticle = (body) ->
  $ = cheerio.load body
  do
    link: origin + $ '.content-inner > .heading > h3 > a' .attr 'href'
    title: $ '.content-inner > .heading > h3 > a' .text!
    img-src: $ '.content-inner > .col-md-12 > .text' .children!first!attr 'src'
    content: $ '.content-inner > .col-md-12 > .text' .children!text!

getPages = (body) ->
  $ = cheerio.load body
  $ '.pagination' .children!first!text!match /共 (\d) 頁/ .1

getItems = (body) ->
  $ = cheerio.load body
  items = $ '.thum-box > a' .map (,it) ->
    id = ~~($ it .attr 'href' .match /(\d+)\.html$/ .1)
    do
      id: id
      #link: origin + $ it .attr 'href'
      link: host + "/news/#{id}"
      img-src: $ it .children!attr 'src'
      caption: $ it .children!attr 'alt' .trim!
      intro-text: $ it .parent!children!children!next!children!text!trim!
  items .= to-array!

module.exports = Api