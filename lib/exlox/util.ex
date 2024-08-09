defmodule Exlox.Util do
  alias Exlox.Scanner

  def tokenize(input) do
    case Scanner.scan_tokens(input) do
      {:ok, tokens} -> tokens
      {:error, err} -> err
    end
  end
end
