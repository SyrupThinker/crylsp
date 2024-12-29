require "json"
require "uri/json"

module LSP::Messages
  class DidChangeTextDocumentParams
    include JSON::Serializable

    @[JSON::Field(key: "textDocument")]
    property text_document : Types::VersionedTextDocumentIdentifier
    @[JSON::Field(key: "contentChanges")]
    property content_changes : Array(Types::TextDocumentContentChangeEvent)
  end

  class DidCloseTextDocumentParams
    include JSON::Serializable

    @[JSON::Field(key: "textDocument")]
    property text_document : Types::TextDocumentIdentifier
  end

  class DidOpenTextDocumentParams
    include JSON::Serializable

    @[JSON::Field(key: "textDocument")]
    property text_document : Types::TextDocumentItem
  end

  class DocumentFormattingParams
    include JSON::Serializable

    @[JSON::Field(key: "textDocument")]
    property text_document : Types::TextDocumentIdentifier
    property options : Types::FormattingOptions
  end

  class InitializeParams
    include JSON::Serializable

    @[JSON::Field(key: "processId")]
    property process_id : Int32?
    @[JSON::Field(key: "clientInfo")]
    property client_info : Types::ClientInfo?
    property locale : String?
    @[JSON::Field(key: "rootUri")]
    property root_uri : URI?
    @[JSON::Field(key: "initializationOptions")]
    property initialization_options : JSON::Any?
    property capabilities : Types::ClientCapabilities
  end

  class InitializeResult
    include JSON::Serializable

    property capabilities : Types::ServerCapabilities
    @[JSON::Field(key: "serverInfo")]
    property server_info : Types::ServerInfo?

    def initialize(@capabilities, @server_info = nil)
    end
  end

  class PublishDiagnosticsParams
    include JSON::Serializable

    property uri : URI
    property diagnostics : Array(Types::Diagnostic)

    def initialize(@uri, @diagnostics)
    end
  end

  class TextEdit
    include JSON::Serializable

    property range : Types::Range
    @[JSON::Field(key: "newText")]
    property new_text : String

    def initialize(@range, @new_text)
    end
  end
end
