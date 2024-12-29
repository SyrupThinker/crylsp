require "uri"

def URI.new_file(path : String) : URI
  URI.new scheme: "file", host: "", path: path
end
