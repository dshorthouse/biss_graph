#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'
require "taxpub"
require "rqrcode"
require "i18n"
require "bitly"

I18n.available_locales = [:en]

TAXPUB_DIR = "xml_docs"
QRCODE_DIR = "qrcodes"

tp = TaxPub.new

@authors = {}

Dir.entries(TAXPUB_DIR).each do |file_name|
  next if File.directory? file_name
  begin
    tp.file_path = File.join(TAXPUB_DIR, file_name)
    tp.parse
    tp.authors.each do |author|
      @authors[author[:fullname]] = { fullname: author[:fullname] }
      if !author[:orcid].empty?
        @authors[author[:fullname]][:orcid] = author[:orcid]
      end
    end
  rescue
  end
end

TEMPLATE = "<!DOCTYPE html>"\
"<html>"\
"<head>"\
"<meta charset='UTF-8'>"\
"<link rel=\"stylesheet\" href=\"https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css\" integrity=\"sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T\" crossorigin=\"anonymous\">"\
"<title>{name}</title>"\
"</head>"\
"<body>"\
"<h1>{name}</h1>"\
"<ul class=\"list-group\">"\
"{orcid}"\
"</ul>"\
"<h2>Co-authors</h2>"\
"</body>"\
"</html>"

Bitly.use_api_version_3
username = "o_2uovprst7s"
api_key = "R_1d83cbb5b679484b87b179dfdd080f39"
bitly = Bitly.new(username, api_key)

@authors.each do |key, author|
  # Make the QR codes using Bitly URLs
  url_friendly_name = CGI::escape(I18n.transliterate(author[:fullname].gsub("'","")))
  url = "https://dshorthouse.github.io/biss_graph/pages/#{url_friendly_name}.html"

  if !File.exist?(File.join(QRCODE_DIR, "#{url_friendly_name}.svg"))
    bitly_short = bitly.shorten(url)
    bitly_url = "https://bit.ly/" + bitly_short.user_hash
    qrcode = RQRCode::QRCode.new(bitly_url)
    svg = qrcode.as_svg(
      color: "ffffff",
      module_size: 1.5
    )
    IO.write(File.join(QRCODE_DIR, "#{url_friendly_name}.svg"), svg.to_s)
    sleep(0.5)
  end

  # Make the HTML pages
  template = TEMPLATE.dup
  orcid = ""
  if author[:orcid]
    orcid = "<li class=\"list-group-item\"><a href=\"#{author[:orcid]}\"><img alt=\"ORCID logo\" src=\"https://orcid.org/sites/default/files/images/orcid_16x16.png\" width=\"16\" height=\"16\" hspace=\"4\" /> #{author[:orcid]}</a></li>"
  end
  html = template.gsub("{name}", author[:fullname]).gsub("{orcid}", orcid)
  IO.write(File.join("pages", "#{url_friendly_name}.html"), html)
end





