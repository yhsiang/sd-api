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

Api.route '/albums'
  .get (req, res) ->
    error, response, body <- request "http://taipeihope.tw/gallery/album.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getAlbums body

Api.route '/albums/:id'
  .get (req, res) ->
    id = req.param 'id'
    error, response, body <- request "http://taipeihope.tw/gallery/album/#{id}.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getPhotos body

Api.route '/policies'
  .get (req, res) ->
    error, response, body <- request "http://taipeihope.tw/issue/issue-list/official-policy.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getPolicies body

Api.route '/policies/:id'
  .get (req, res) ->
    id = req.param 'id'
    error, response, body <- request "http://taipeihope.tw/issue/issue-list/official-policy/topic/#{id}.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: [ getPolicy body ]

Api.route '/advisors'
  .get (req, res) ->
    { page } = req.query
    error, response, body <- request "http://taipeihope.tw/issue/municipal-advisors.html?start=#{page * 4}"

    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getAdvisors body
      page-info:
        total-pages: getPages body
        results-per-page: 4

Api.route '/proposals'
  .get (req, res) ->
    {page} = req.query
    error, response, body <- request "http://taipeihope.tw/issue/issue-list/proposal.html?start=#{page * 6}"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: getProposals body
      page-info:
        total-pages: getPages body
        results-per-page: 6

Api.route '/proposals/:id'
  .get (req, res)->
    id = req.param 'id'
    error, response, body <- request "http://taipeihope.tw/issue/issue-list/proposal/topic/#{id}.html"
    res.json do
      is-success: true
      error-code: 0
      error-message: null
      data: [ getProposal body ]

getProposal = (body) ->
  $ = cheerio.load body
  do
    yes: $ '.boxbtm-default > .yes' .text!trim!
    no: $ '.boxbtm-default > .no' .text!trim!
    title: $ '.topic-item-inner > .heading' .text!trim!
    content: $ '.topic-item-inner > .content > .content-inner > .col-md-12' .text!trim!

getProposals = (body) ->
  $ = cheerio.load body
  items = $ '.topics-item' .map (,it) ->
    yes-no = $ it .children!first!children!
    info = $ it .children!first!next!children!first!
    id = $ info .attr 'href' .match /(\d+)\.html$/ .1
    do
      id: ~~id
      yes: $ yes-no .first!text!trim!
      no: $ yes-no .first!next!text!trim!
      link: host + "/v1/proposals/#{id}" #$ info .attr 'href'
      img-src: $ info .children!attr 'src'
      title: $ info .children!attr 'alt' .trim!
      proposer: $ it .children!first!next!children!eq 2 .text!trim!match /.+：(.+)/ .1

  items .= to-array!

getAdvisors = (body) ->
  $ = cheerio.load body
  items = $ '.members-item-inner' .map (,it)->
    do
      name: $ it .children!first!text!trim!
      title: $ it .children!first!next!text!trim!
      img-src:$ it .children!first!next!next!children!children!children!attr 'src'
      info: $ it .children!first!next!next!children!children!next!text!trim!

  items .= to-array!
getPolicy = (body) ->
  $ = cheerio.load body
  do
    link: origin + $ '.heading > h2 > a' .attr 'href'
    title: $ '.heading > h2 > a' .text!
    img-src: origin + $ '.content-inner > .col-md-12 > .content-img > img' .attr 'src'
    content: $ '.content-inner > .col-md-12 > .text' .children!text!

getPolicies = (body) ->
  $ = cheerio.load body
  items = $ '.topics-item-inner' .map (,it) ->
    id = $ it .children!attr 'href' .match /(\d+)\.html$/ .1
    do
      id: id
      link: host + "/v1/policies/#{id}"#origin + $ it .children!attr 'href'
      img-src: $ it .children!children!attr 'src'
      title: $ it .children!children!attr 'alt' .trim!

  items .= to-array!

getPhotos = (body) ->
  $ = cheerio.load body
  items = $ '.fsThumb' .map (,it) ->
    do
      title: $ it .children!next!text!
      img-src: $ it .children!next!next!attr 'style' .match /background-image: url\((.+)\)/ .1
  items .= to-array!

getAlbums = (body) ->
  $ = cheerio.load body
  items = $ '.fsThumb' .map (,it) ->
    id = $ it .attr 'onclick' .match /\/(\w+)\.html';$/ .1
    link = $ it .attr 'onclick' .match /javascript: window.location.href='(.+)';/ .1
    do
      id: id
      link: origin + link
      title: $ it .children!next!text!
      img-src: $ it .children!next!next!attr 'style' .match /background-image: url\((.+)\)/ .1
  items .= to-array!

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
      link: host + "/v1/news/#{id}"
      img-src: $ it .children!attr 'src'
      caption: $ it .children!attr 'alt' .trim!
      intro-text: $ it .parent!children!children!next!children!text!trim!
  items .= to-array!

module.exports = Api