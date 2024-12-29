require "./extensions"
require "./mappers"
require "./crylsp/*"
require "./lsp"

require "option_parser"

Log.setup :trace, Log::IOBackend.new STDERR

OptionParser.parse do |parser|
  parser.banner = "Usage: crylsp"
  parser.on "-h", "--help", "Show this help" do
    puts parser
    exit
  end
end

server = LSP::Server.new STDIN, STDOUT,
  LSP::Types::ServerCapabilities.new(document_formatting_provider: true),
  enable_document_sync: true

ameba_linter = CryLSP::AmebaLinter.new server

server.on_file_changed do |uri|
  ameba_linter.run uri
end

server.on_initialized do
  spawn do
    ameba_linter.run
  end

  if path = server.init.try &.root_uri.try &.path
    entrypoints = CryLSP::Workspace.find_entrypoints Path[path]
    STDERR.puts "Entrypoints:", entrypoints
  end
end

server.def_method "textDocument/formatting" do |request|
  CryLSP::Formatter.format server, request
end

server.def_notification "workspace/didChangeWatchedFiles" do
  spawn do
    ameba_linter.run
  end
end

exit server.run
