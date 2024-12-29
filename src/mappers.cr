require "./lsp"

require "ameba"

enum Ameba::Severity
  def to_lsp
    case self
    when Ameba::Severity::Error      then LSP::Types::DiagnosticSeverity::Error
    when Ameba::Severity::Warning    then LSP::Types::DiagnosticSeverity::Warning
    when Ameba::Severity::Convention then LSP::Types::DiagnosticSeverity::Information
    else                                  LSP::Types::DiagnosticSeverity::Hint
    end
  end
end

class Crystal::Location
  def to_lsp
    LSP::Types::Position.new(line: (line_number - 1).to_u, character: (column_number - 1).to_u)
  end
end
