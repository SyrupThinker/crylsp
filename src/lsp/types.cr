require "json"
require "uri/json"

module LSP::Types
  alias TextDocumentContentChangeEvent = TextDocumentContentChangeEventPartial | TextDocumentContentChangeEventFull

  struct ClientCapabilities
    include JSON::Serializable

    @[JSON::Field(key: "textDocument")]
    property text_document : TextDocumentClientCapabilities?
  end

  struct ClientInfo
    include JSON::Serializable

    property name : String
    property version : String?
  end

  struct DiagnosticClientCapabilities
    include JSON::Serializable
  end

  struct DocumentFormattingClientCapabilities
    include JSON::Serializable
  end

  struct Diagnostic
    include JSON::Serializable

    property range : Range
    @[JSON::Field(converter: Enum::ValueConverter(LSP::Types::DiagnosticSeverity))]
    property severity : DiagnosticSeverity?
    property source : String?
    property message : String

    def initialize(@range, @message, @severity = nil, @source = nil)
    end
  end

  struct DiagnosticOptions
    include JSON::Serializable

    @[JSON::Field(key: "interFileDependencies")]
    property? inter_file_dependencies : Bool
    @[JSON::Field(key: "workspaceDiagnostics")]
    property? workspace_diagnostics : Bool

    def initialize(@inter_file_dependencies, @workspace_diagnostics)
    end
  end

  enum DiagnosticSeverity
    Error       = 1
    Warning     = 2
    Information = 3
    Hint        = 4
  end

  struct FormattingOptions
    include JSON::Serializable

    @[JSON::Field(key: "tabSize")]
    property tab_size : Int32
    @[JSON::Field(key: "insertSpaces")]
    property? insert_spaces : Bool
    @[JSON::Field(key: "trimTrailingWhitespace")]
    property? trim_trailing_whitespace : Bool?
    @[JSON::Field(key: "insertFinalNewline")]
    property? insert_final_newline : Bool?
    @[JSON::Field(key: "trimFinalNewlines")]
    property? trim_final_newlines : Bool?
  end

  struct Position
    include JSON::Serializable

    # Zero-based line position in a document.
    property line : UInt32
    # Zero-based character offset on a line in a document.
    #
    # The meaning is determined by the `position_encoding_type`.
    property character : UInt32

    def initialize(@line, @character)
    end

    def to(end_inclusive : Position) : Range
      Range.new self, Position.new(end_inclusive.line, end_inclusive.character + 1)
    end

    def to_exclusive(end_exclusive : Position) : Range
      Range.new self, end_exclusive
    end
  end

  struct PublishDiagnosticsClientCapabilities
    include JSON::Serializable
  end

  struct Range
    include JSON::Serializable

    property start : Position
    property end : Position

    def initialize(@start, @end)
    end
  end

  struct ServerInfo
    include JSON::Serializable

    property name : String
    property version : String?

    def initialize(@name, @version = nil)
    end
  end

  struct ServerCapabilities
    include JSON::Serializable

    @[JSON::Field(key: "positionEncoding")]
    property position_encoding : String?
    @[JSON::Field(key: "textDocumentSync")]
    property text_document_sync : TextDocumentSyncOptions?
    @[JSON::Field(key: "documentFormattingProvider")]
    property? document_formatting_provider : Bool?
    @[JSON::Field(key: "diagnosticProvider")]
    property diagnostic_provider : Types::DiagnosticOptions?

    def initialize(@position_encoding = nil, @document_formatting_provider = nil, @diagnostic_provider = nil)
    end
  end

  struct TextDocumentClientCapabilities
    include JSON::Serializable

    property formatting : DocumentFormattingClientCapabilities?
    property diagnostic : DiagnosticClientCapabilities?
    @[JSON::Field(key: "publishDiagnostics")]
    property publish_diagnostics : PublishDiagnosticsClientCapabilities?
  end

  struct TextDocumentContentChangeEventFull
    include JSON::Serializable

    property text : String
  end

  struct TextDocumentContentChangeEventPartial
    include JSON::Serializable

    property range : Range
    property range_length : Int32?
    property text : String
  end

  struct TextDocumentIdentifier
    include JSON::Serializable

    property uri : URI
  end

  struct TextDocumentItem
    include JSON::Serializable

    property uri : URI
    @[JSON::Field(key: "languageId")]
    property language_id : String
    property version : Int32
    property text : String

    def initialize(@uri, @language_id, @version, @text)
    end
  end

  enum TextDocumentSyncKind
    None        = 0
    Full        = 1
    Incremental = 2
  end

  struct TextDocumentSyncOptions
    include JSON::Serializable

    @[JSON::Field(key: "openClose")]
    property open_close : Bool?
    @[JSON::Field(converter: Enum::ValueConverter(LSP::Types::TextDocumentSyncKind))]
    property change : TextDocumentSyncKind?

    def initialize(@open_close = nil, @change = nil)
    end
  end

  struct VersionedTextDocumentIdentifier
    include JSON::Serializable

    property uri : URI
    property version : Int32
  end
end
