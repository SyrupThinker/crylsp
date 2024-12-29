class LSP::Server
  private DEFAULT_CONTENT_TYPE = "application/vscode-jsonrpc; charset=utf-8"
  private CONTENT_LENGTH       = "Content-Length"
  private CONTENT_TYPE         = "Content-Type"

  getter init : Messages::InitializeParams?

  @exit_code : Int32?
  @status : Status = :uninitialized

  @file_changed_callback : Proc(URI, Nil)?
  @initialized_callback : Proc(Nil)?
  @notification_handler = Hash(String, NotificationHandler).new
  @response_callback = Hash(UInt64, ResponseHandler).new
  @request_handler = Hash(String, RequestHandler).new

  @client_documents = Hash(URI, String).new

  @out_mutex = Mutex.new
  @outgoing_request_counter = 0

  alias NotificationHandler = RPC::Notification -> Nil
  alias ResponseHandler = RPC::Response -> Nil
  alias RequestHandler = RPC::Request -> Nil

  enum Status
    Uninitialized
    Initialized
    Shutdown
  end

  def initialize(@in : IO, @out : IO, @capabilities : Types::ServerCapabilities, enable_document_sync : Bool = false)
    enable_text_document_sync if enable_document_sync

    def_method "initialize" do |request|
      params = request.params_as Messages::InitializeParams

      @init = params
      if root = params.root_uri.try &.path
        Dir.cd root
      end

      send_rpc request.new_response Messages::InitializeResult.new capabilities: @capabilities, server_info: Types::ServerInfo.new(name: "crylsp", version: "dev")
      @status = :initialized
    end

    def_notification "initialized" do
      @initialized_callback.try &.call
    end

    def_method "shutdown" do |request|
      send_rpc request.new_response nil
      @status = :shutdown
    end

    def_notification "exit" do
      @exit_code = @status == :shutdown ? 0 : 1
    end
  end

  def def_method(name : String, &handler : RequestHandler)
    @request_handler[name] = handler
  end

  def def_notification(name : String, &handler : NotificationHandler)
    @notification_handler[name] = handler
  end

  def get_file_content(identifier) : String
    uri = if identifier.is_a? Types::TextDocumentIdentifier | Types::TextDocumentItem | Types::VersionedTextDocumentIdentifier
            identifier.uri
          elsif identifier.is_a? URI
            identifier
          else
            URI.new_file File.expand_path identifier
          end

    @client_documents[uri]? || File.read uri.path
  end

  def on_file_changed(&block : URI -> Nil)
    @file_changed_callback = block
  end

  def on_initialized(&block : -> Nil)
    @initialized_callback = block
  end

  def run : Int32
    until code = @exit_code
      case rpc = read_rpc
      when RPC::Notification
        if handler = @notification_handler[rpc.method]?
          handler.call rpc
        end
      when RPC::Response
        if callback = @response_callback.delete rpc.id
          callback.call rpc
        end
      when RPC::Request
        if handler = @request_handler[rpc.method]?
          handler.call rpc
        else
          Log.warn &.emit("Unhandled RPC method call", rpc: rpc.inspect)
        end
      end
    end

    code
  rescue e
    Log.error(exception: e) { "Server failed with exception" }
    1
  end

  private def enable_text_document_sync
    @capabilities.text_document_sync = Types::TextDocumentSyncOptions.new open_close: true, change: :full

    def_notification "textDocument/didOpen" do |request|
      params = request.params_as Messages::DidOpenTextDocumentParams
      @client_documents[params.text_document.uri] = params.text_document.text
    end

    def_notification "textDocument/didChange" do |request|
      params = request.params_as Messages::DidChangeTextDocumentParams
      @client_documents[params.text_document.uri] = params.content_changes.first.text
      @file_changed_callback.try &.call params.text_document.uri
    end

    def_notification "textDocument/didClose" do |request|
      params = request.params_as Messages::DidCloseTextDocumentParams
      @client_documents.delete params.text_document.uri
    end
  end

  private def read_message
    headers = {} of String => String

    while line = @in.gets "\r\n", chomp: true
      break if line.empty?
      name, value = line.split ": ", limit: 2
      headers[name] = value
    end

    unless length = headers[CONTENT_LENGTH]?
      Log.error &.emit("Missing required header #{CONTENT_LENGTH}", headers: headers)
      raise ProtocolViolationError.new "Missing required header #{CONTENT_LENGTH}"
    end
    content = Bytes.new length.to_i
    @in.read_fully content

    Transport::Message.new headers, content
  end

  private def read_rpc
    message = read_message
    raise ProtocolViolationError.new "Invalid #{CONTENT_TYPE} for RPC message" unless (message.headers[CONTENT_TYPE]? || DEFAULT_CONTENT_TYPE) == DEFAULT_CONTENT_TYPE

    # TODO: Intermediate struct is not really needed, could parse from stream.
    rpc = RPC::AnyMessage.from_json IO::Memory.new message.body
    Log.debug &.emit("RPC RX", rpc: rpc.inspect)
    rpc
  end

  private def send_message(message : Transport::Message)
    @out_mutex.synchronize do
      message.headers.each do |name, value|
        @out.printf "%s: %s\r\n", name, value
      end
      @out << "\r\n"
      @out.write message.body
      @out.flush
    end
  end

  def send_rpc(rpc : RPC::AnyMessage)
    body = rpc.to_json.to_slice
    send_message Transport::Message.new headers: {CONTENT_LENGTH => body.size.to_s}, body: body[..]
    Log.debug &.emit("RPC TX", rpc: rpc.inspect)
  end
end
