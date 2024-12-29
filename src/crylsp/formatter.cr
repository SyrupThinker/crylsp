require "./compiler_requires"

class CryLSP::Formatter
  def self.format(server : LSP::Server, request : LSP::RPC::Request) : Nil
    params = request.params_as LSP::Messages::DocumentFormattingParams
    uri = params.text_document.uri
    unless Path[uri.path].extension == ".cr"
      server.send_rpc request.new_response nil
      return
    end

    spawn do
      begin
        input = server.get_file_content uri
        formatted = Crystal.format input
        server.send_rpc request.new_response [
          LSP::Messages::TextEdit.new LSP::Types::Position.new(0, 0)
            .to_exclusive(LSP::Types::Position.new(input.lines.size.to_u, 0)),
            new_text: formatted,
        ]
      rescue e
        Log.error(exception: e) { "Failed to format document" }
        # TODO: Report actual error
        server.send_rpc request.new_response nil
      end
    end
  end
end
