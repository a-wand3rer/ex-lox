defmodule Exlox.ScanError do
  alias __MODULE__
  @enforce_keys [:message, :line]
  defstruct [:message, :line, :char]

  def new(message, line, char \\ nil) do
    %ScanError{message: message, line: line, char: char}
  end
end
