defmodule ExloxScannerTest do
  alias Exlox.Token
  alias Exlox.Scanner
  use ExUnit.Case
  doctest Exlox.Scanner

  test "parse single char lexeme" do
    assert Scanner.scan_tokens("(") == {:ok, [%Token{type: :left_paren, line: 1}]}
    assert Scanner.scan_tokens(")") == {:ok, [%Token{type: :right_paren, line: 1}]}

    assert Scanner.scan_tokens("{}") ==
             {:ok, [%Token{type: :left_brace, line: 1}, %Token{type: :right_brace, line: 1}]}

    assert Scanner.scan_tokens(",.-+;*") ==
             {:ok,
              [
                %Token{type: :comma, line: 1},
                %Token{type: :dot, line: 1},
                %Token{type: :minus, line: 1},
                %Token{type: :plus, line: 1},
                %Token{type: :semicolon, line: 1},
                %Token{type: :star, line: 1}
              ]}
  end

  test "parse operator" do
    assert Scanner.scan_tokens("!") == {:ok, [%Token{type: :bang, line: 1}]}
    assert Scanner.scan_tokens("!=") == {:ok, [%Token{type: :bang_equal, line: 1}]}
    assert Scanner.scan_tokens(">") == {:ok, [%Token{type: :greater, line: 1}]}
    assert Scanner.scan_tokens(">=") == {:ok, [%Token{type: :greater_equal, line: 1}]}
    assert Scanner.scan_tokens("<=") == {:ok, [%Token{type: :less_equal, line: 1}]}
    assert Scanner.scan_tokens("<") == {:ok, [%Token{type: :less, line: 1}]}
    assert Scanner.scan_tokens("==") == {:ok, [%Token{type: :equal_equal, line: 1}]}
    assert Scanner.scan_tokens("=") == {:ok, [%Token{type: :equal, line: 1}]}
  end

  test "parse comment" do
    assert Scanner.scan_tokens("/") == {:ok, [%Token{type: :slash, line: 1}]}
    assert Scanner.scan_tokens("// this is a commend \n!") == {:ok, [%Token{type: :bang, line: 2}]}
  end

  test "grouping stuff" do
    assert Scanner.scan_tokens("(( )){} // grouping stuff") == {:ok, [
      %Token{type: :left_paren, line: 1},
      %Token{type: :left_paren, line: 1},
      %Token{type: :right_paren, line: 1},
      %Token{type: :right_paren, line: 1},
      %Token{type: :left_brace, line: 1},
      %Token{type: :right_brace, line: 1},
    ]}
  end

  test "parse string" do
    assert Scanner.scan_tokens("\"hello\"") == {:ok, [%Token{type: :string, line: 1, literal: "hello"}]}
    assert Scanner.scan_tokens("\"hello\nworld\"") == {:ok, [%Token{type: :string, line: 1, literal: "helloworld"}]}
    assert Scanner.scan_tokens("\"Abc") == {:error, ["unterminated string"]}
  end

  test "parse number" do
    assert Scanner.scan_tokens("123") == {:ok, [%Token{type: :number, line: 1, literal: 123.0}]}
    assert Scanner.scan_tokens("123.45") == {:ok, [%Token{type: :number, line: 1, literal: 123.45}]}
    assert Scanner.scan_tokens(".123") == {:error, ["unexpected character"]}
    assert Scanner.scan_tokens("123.") == {:error, ["unexpected character"]}
    assert Scanner.scan_tokens("123.3.") == {:error, ["unexpected character"]}
  end
end
