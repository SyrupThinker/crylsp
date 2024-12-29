require "ameba"

require "../lsp"

class Ameba::Config
  property lsp_server : LSP::Server?

  def sources
    # Support fetching sources from the LSP server.
    return previous_def unless server = @lsp_server

    Log.debug { "Fetching Ameba sources from LSP server" }

    (find_files_by_globs globs - find_files_by_globs excluded)
      .map { |path| Source.new server.get_file_content(path), path }
  end
end

class CryLSP::AmebaLinter
  @active_diagnostic_uris = Set(URI).new
  @running = Atomic(Bool).new false

  def initialize(@server : LSP::Server)
  end

  def run(file : URI? = nil) : Nil
    return if @running.swap true, :acquire

    begin
      return unless init = @server.init
      return unless init.capabilities.text_document.try &.publish_diagnostics
      return if init.root_uri.nil?

      Log.info { "Running Ameba" }

      sources = File.open File::NULL, "w" do |null|
        config = Ameba::Config.load
        config.formatter = Ameba::Formatter::BaseFormatter.new null
        config.globs = [file.path] if file
        config.lsp_server = @server

        runner = Ameba::Runner.new config
        runner.run

        runner.sources
      end

      current_diagnostic_uris = Set(URI).new

      sources.each do |source|
        next if source.issues.empty?

        diags = source.issues.compact_map do |issue|
          next unless loc = issue.location

          end_loc = issue.end_location || loc
          range = loc.to_lsp.to end_loc.to_lsp

          LSP::Types::Diagnostic.new range: range, message: issue.message, severity: issue.rule.severity.to_lsp, source: "crylsp:Ameba:#{issue.rule.name}"
        end

        uri = URI.new_file source.fullpath
        params = LSP::Messages::PublishDiagnosticsParams.new uri: uri, diagnostics: diags
        rpc = LSP::RPC::Notification.new method: "textDocument/publishDiagnostics", params: params
        @server.send_rpc rpc

        current_diagnostic_uris.add uri
      end

      previous = file ? Set(URI){file} : @active_diagnostic_uris # Only invalidate updated diagnostics.
      (previous - current_diagnostic_uris).each do |stale_uri|
        params = LSP::Messages::PublishDiagnosticsParams.new uri: stale_uri, diagnostics: [] of LSP::Types::Diagnostic
        rpc = LSP::RPC::Notification.new method: "textDocument/publishDiagnostics", params: params
        @server.send_rpc rpc
      end

      @active_diagnostic_uris = current_diagnostic_uris
    ensure
      @running.set false, :release
    end
  end
end
