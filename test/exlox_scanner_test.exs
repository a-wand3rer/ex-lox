defmodule ExloxScannerTest do
  alias Exlox.ScanError
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

    assert Scanner.scan_tokens("// this is a commend \n!") ==
             {:ok, [%Token{type: :bang, line: 2}]}
  end

  test "grouping stuff" do
    assert Scanner.scan_tokens("(( )){} // grouping stuff") ==
             {:ok,
              [
                %Token{type: :left_paren, line: 1},
                %Token{type: :left_paren, line: 1},
                %Token{type: :right_paren, line: 1},
                %Token{type: :right_paren, line: 1},
                %Token{type: :left_brace, line: 1},
                %Token{type: :right_brace, line: 1}
              ]}
  end

  test "parse string" do
    assert Scanner.scan_tokens("\"hello\"") ==
             {:ok, [%Token{type: :string, line: 1, literal: "hello"}]}

    assert Scanner.scan_tokens("\"hello\nworld\"") ==
             {:ok, [%Token{type: :string, line: 1, literal: "helloworld"}]}

    assert Scanner.scan_tokens("\"Abc") ==
             {:error, [%ScanError{message: "unterminated string", line: 1}]}
  end

  test "parse number" do
    assert Scanner.scan_tokens("123") == {:ok, [%Token{type: :number, line: 1, literal: 123.0}]}

    assert Scanner.scan_tokens("123 456") ==
             {:ok,
              [
                %Token{type: :number, line: 1, literal: 123.0},
                %Token{type: :number, line: 1, literal: 456.0}
              ]}

    assert Scanner.scan_tokens("123.45") ==
             {:ok, [%Token{type: :number, line: 1, literal: 123.45}]}

    assert Scanner.scan_tokens("123.45, 100") ==
             {:ok,
              [
                %Token{type: :number, line: 1, literal: 123.45},
                %Token{type: :comma, line: 1, literal: nil},
                %Token{type: :number, line: 1, literal: 100.0}
              ]}

    assert Scanner.scan_tokens(".123") ==
             {:error, [%ScanError{message: "unexpected character", line: 1, char: "."}]}

    assert Scanner.scan_tokens("123.") ==
             {:error, [%ScanError{message: "unexpected character", line: 1, char: "."}]}

    assert Scanner.scan_tokens("123.3.") ==
             {:error, [%ScanError{message: "unexpected character", line: 1, char: "."}]}

    assert Scanner.scan_tokens("123.3.3") ==
             {:error, [%ScanError{message: "unexpected character", line: 1, char: "."}]}
  end

  test "parsing identifier" do
    assert Scanner.scan_tokens("hello") ==
             {:ok, [%Token{type: :identifier, line: 1, literal: "hello"}]}

    assert Scanner.scan_tokens("hello world") ==
             {:ok,
              [
                %Token{type: :identifier, line: 1, literal: "hello"},
                %Token{type: :identifier, line: 1, literal: "world"}
              ]}

    assert Scanner.scan_tokens("hello123\nworld") ==
             {:ok,
              [
                %Token{type: :identifier, line: 1, literal: "hello123"},
                %Token{type: :identifier, line: 2, literal: "world"}
              ]}

    assert Scanner.scan_tokens("Hello123\nWorld") ==
             {:ok,
              [
                %Token{type: :identifier, line: 1, literal: "Hello123"},
                %Token{type: :identifier, line: 2, literal: "World"}
              ]}

    assert Scanner.scan_tokens("123abc") ==
             {:error, [%ScanError{message: "unexpected character", line: 1, char: "a"}]}
  end
end
