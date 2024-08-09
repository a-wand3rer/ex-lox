defmodule Exlox.Token do
  alias __MODULE__

  @enforce_keys [:type, :line]
  defstruct [:type, :line, :literal]

  @type token_type ::
          :left_paren
          | :right_paren
          | :left_brace
          | :right_brace
          | :comma
          | :dot
          | :minus
          | :plus
          | :semicolon
          | :slash
          | :star
          | :bang
          | :bang_equal
          | :equal
          | :equal_equal
          | :greater
          | :greater_equal
          | :less
          | :less_equal
          | :identifier
          | :string
          | :number
          | :and
          | :class
          | :else
          | false
          | :fun
          | :for
          | :if
          | nil
          | :or
          | :print
          | :return
          | :super
          | :this
          | true
          | :var
          | :while
          | :eof

  @type t :: %Token{type: token_type(), line: non_neg_integer(), literal: any()}

  @spec new(token_type(), non_neg_integer()) :: t()
  def new(type, line) do
    %Token{type: type, line: line}
  end

  def new(type, line, literal) do
    %Token{type: type, line: line, literal: literal}
  end
end
