#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'
require "taxpub"
require "rqrcode"

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

template = "<!DOCTYPE html>"\
"<html>"\
"<head>"\
"<meta charset='UTF-8'>"\
"<title>{name}</title>"\
"</head>"\
"<body>"\
"<h1>{name}</h1>"\
"</body>"\
"</html>"

@authors.each do |key, author|
  url_friendly_name = CGI::escape(author[:fullname])
  qrcode = RQRCode::QRCode.new("https://dshorthouse.github.io/biss_graph/pages/#{url_friendly_name}.html")
  svg = qrcode.as_svg(
    color: "ffffff",
    module_size: 1
  )
  IO.write(File.join(QRCODE_DIR, "#{author[:fullname]}.svg"), svg.to_s)
  template.gsub!("{name}", author[:fullname])
  IO.write(File.join("pages", "#{url_friendly_name}.html"), template)
end





