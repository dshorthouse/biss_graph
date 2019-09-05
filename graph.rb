#!/usr/bin/env ruby
# encoding: utf-8

require "active_record"
require "taxpub"
require_relative "weighted_graph.rb"

TAXPUB_DIR = "xml_docs"
QRCODE_DIR = "qrcodes"

RGL::DOT::EDGE_OPTS << 'penwidth'

graph_options = {
  bgcolor: "#000000",
  splines: true
}

vertex_options = {
  color: "#7FFF00",
  penwidth: 8,
  style: "filled",
  fillcolor: "#0912ba",
  fontcolor: "#ffffff",
  fontname: "Arial",
  fontsize: 24
}

edge_options = {
  color: "#FCF340",
  penwidth: 2
}

wg = WeightedGraph.new
wg.add_graph_attributes(graph_options)

tp = TaxPub.new

Dir.entries(TAXPUB_DIR).each do |file_name|
  next if File.directory? file_name
  begin
    tp.file_path = File.join(TAXPUB_DIR, file_name)
    tp.parse
    tp.authors.combination(2).each do |pair|
      wg.add_edge(pair[0][:fullname], pair[1][:fullname], nil)
      wg.add_edge_attributes(pair[0][:fullname], pair[1][:fullname], edge_options)
    end
    tp.authors.each do |author|
      qr_file = File.join(QRCODE_DIR, "#{author[:fullname]}.svg")
      opts = {
        label: "<<table border=\"0\" cellborder=\"0\" cellspacing=\"0\"><tr><td><img src=\"#{qr_file}\" /></td><td>#{author[:fullname]}</td></tr></table>>"
      }
      wg.add_vertex_attributes(author[:fullname], vertex_options.merge(opts))
    end
  rescue
  end
end

wg.write_to_dot_file("biss_coauthors")

# sfdp -Goutputorder=edgesfirst -Goverlap=prism -Tsvg biss_coauthors.dot > biss_coauthors.svg

