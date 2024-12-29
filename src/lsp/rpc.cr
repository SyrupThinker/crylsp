require "json"

module LSP::RPC
  alias AnyMessage = Notification | Response | Request
  alias Payload = Array(JSON::Any) | Hash(String, JSON::Any)

  struct Error
    include JSON::Serializable

    property code : Int32
    property message : String
    property data : JSON::Any

    enum Codes
      ParseError     = -32700
      InvalidRequest = -32600
      MethodNotFound = -32601
      InvalidParams  = -32602
      InternalError  = -32603

      ServerNotInitialized = -32002
      UnknownErrorCode     = -32001

      RequestFailed    = -32803
      ServerCancelled  = -32802
      ContentModified  = -32801
      RequestCancelled = -32800
    end
  end

  class Notification
    include JSON::Serializable

    property jsonrpc : String = "2.0"
    @[JSON::Field(ignore_serialize: true)]
    property id : Nil
    property method : String
    property params : Payload?

    def initialize(@method, params)
      # TODO: Avoid intermediate serialization
      @params = Payload.from_json params.to_json
    end

    def params_as(t)
      # TODO: Avoid intermediate serialization
      t.from_json params.to_json
    end
  end

  class Response
    include JSON::Serializable

    property jsonrpc : String = "2.0"
    property id : Int32 | String | Nil
    property result : JSON::Any?
    property error : Error?

    def initialize(@id, result, @error)
      @result = JSON::Any.from_json result.to_json
    end
  end

  class Request
    include JSON::Serializable

    property jsonrpc : String = "2.0"
    property id : Int32 | String
    property method : String
    property params : Payload?

    def initialize(@id, @method, @params)
    end

    def new_response(result)
      if result.is_a? Error
        Response.new id: id, result: nil, error: result
      else
        Response.new id: id, result: result, error: nil
      end
    end

    def params_as(t)
      # TODO: Avoid intermediate serialization
      t.from_json params.to_json
    end
  end
end
