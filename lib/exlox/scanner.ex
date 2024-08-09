defmodule Exlox.Scanner do
  alias Exlox.ScanError
  alias __MODULE__
  alias Exlox.Token

  @type result :: {:ok, list(Token.t())} | {:error, list(String.t())}
  @type error :: String.t()
  @type t :: %Scanner{tokens: list(Token.t()), errors: list(error()), line: pos_integer()}

  @single_char_token_map %{
    ?( => :left_paren,
    ?) => :right_paren,
    ?{ => :left_brace,
    ?} => :right_brace,
    ?, => :comma,
    ?. => :dot,
    ?- => :minus,
    ?+ => :plus,
    ?* => :star,
    ?; => :semicolon,
    ?! => :bang,
    ?= => :equal,
    ?> => :greater,
    ?< => :less,
    ?/ => :slash
  }

  @keywords_map %{
    "and" => :and,
    "class" => :class,
    "else" => :else,
    "false" => false,
    "for" => :for,
    "fun" => :fun,
    "if" => :if,
    "nil" => nil,
    "or" => :or,
    "print" => :print,
    "return" => :return,
    "super" => :super,
    "this" => :this,
    "true" => true,
    "var" => :var,
    "while" => :while
  }

  defstruct tokens: [], errors: [], line: 1

  defguardp is_whitespace(c) when c in [?\s, ?\r, ?\t]
  defguardp is_alpha(c) when c in ?a..?z or c in ?A..?Z or c == ?_
  defguardp is_digit(c) when c in ?0..?9
  defguardp is_alphanumeric(c) when is_alpha(c) or is_digit(c)

  @spec scan_tokens(String.t()) :: result()
  def scan_tokens(source_text) do
    text = String.to_charlist(source_text)
    scan(%Scanner{}, text)
  end

  def scan(%Scanner{tokens: tokens, errors: []}, []) do
    {:ok, Enum.reverse(tokens)}
  end

  def scan(%Scanner{errors: errors}, []) do
    {:error, errors}
  end

  def scan(scanner, text) do
    case text do
      [?( | rest] ->
        add_single_char_token(scanner, ?(, rest)

      [?) | rest] ->
        add_single_char_token(scanner, ?), rest)

      [?{ | rest] ->
        add_single_char_token(scanner, ?{, rest)

      [?} | rest] ->
        add_single_char_token(scanner, ?}, rest)

      [?, | rest] ->
        add_single_char_token(scanner, ?,, rest)

      [?., c | _] when is_digit(c) ->
        add_number(scanner, text, [], 0)

      [?. | rest] ->
        add_single_char_token(scanner, ?., rest)

      [?- | rest] ->
        add_single_char_token(scanner, ?-, rest)

      [?+ | rest] ->
        add_single_char_token(scanner, ?+, rest)

      [?; | rest] ->
        add_single_char_token(scanner, ?;, rest)

      [?* | rest] ->
        add_single_char_token(scanner, ?*, rest)

      [?!, ?= | rest] ->
        scanner |> add_token(:bang_equal) |> scan(rest)

      [?! | rest] ->
        add_single_char_token(scanner, ?!, rest)

      [?>, ?= | rest] ->
        scanner |> add_token(:greater_equal) |> scan(rest)

      [?> | rest] ->
        add_single_char_token(scanner, ?>, rest)

      [?<, ?= | rest] ->
        scanner |> add_token(:less_equal) |> scan(rest)

      [?< | rest] ->
        add_single_char_token(scanner, ?<, rest)

      [?=, ?= | rest] ->
        scanner |> add_token(:equal_equal) |> scan(rest)

      [?= | rest] ->
        add_single_char_token(scanner, ?=, rest)

      [?/, ?/ | rest] ->
        rest
        |> Enum.drop_while(fn c -> c != ?\n end)
        |> then(fn remain -> scan(scanner, remain) end)

      [?/ | rest] ->
        add_single_char_token(scanner, ?/, rest)

      [c | rest] when is_whitespace(c) ->
        scan(scanner, rest)

      [?\n | rest] ->
        scanner |> increase_line() |> scan(rest)

      [?" | rest] ->
        add_string(scanner, rest, [])

      [c | _] when is_digit(c) ->
        add_number(scanner, text, [])

      [c | _] when is_alpha(c) ->
        add_identifier(scanner, text)

      _ ->
        add_error(scanner, "unexpected character")
    end
  end

  @spec add_identifier(any(), any()) :: nil
  def add_identifier(scanner, chars, agg \\ []) do
    case chars do
      [] ->
        scanner
        |> add_identifier_token(to_string_literal(agg))
        |> scan([])

      [c | _] when not is_alphanumeric(c) ->
        scanner
        |> add_identifier_token(to_string_literal(agg))
        |> scan(chars)

      [c | rest] when is_alphanumeric(c) ->
        add_identifier(scanner, rest, [c | agg])
    end
  end

  def add_identifier_token(scanner, literal) do
    token_type = Map.get(@keywords_map, literal, :identifier)
    scanner
    |> add_token(token_type, literal)
  end

  def add_number(scanner, chars, agg, has_dot \\ false) do
    case chars do
      [?., c | _] when is_digit(c) and agg == [] ->
        add_error(scanner, "unexpected character", ".")

      [?.] ->
        add_error(scanner, "unexpected character", ".")

      [c | _] when not is_digit(c) and is_alpha(c) ->
        add_error(scanner, "unexpected character", List.to_string([c]))

      [c | rest] when is_digit(c) ->
        add_number(scanner, rest, [c | agg], has_dot)

      [?., d | _] when is_digit(d) and has_dot ->
        add_error(scanner, "unexpected character", ".")

      [?., d | rest] when is_digit(d) ->
        add_number(scanner, rest, [d, ?. | agg], true)

      [c | _] when not is_digit(c) ->
        scanner
        |> add_number_token(to_number_literal(agg, has_dot))
        |> scan(chars)

      [?\n | rest] ->
        scanner
        |> add_number_token(to_number_literal(agg, has_dot))
        |> increase_line()
        |> scan(rest)

      [] ->
        scanner
        |> add_number_token(to_number_literal(agg, has_dot))
        |> scan([])
    end
  end

  def add_string(scanner, chars, agg) do
    case chars do
      [] ->
        add_error(scanner, "unterminated string")

      [c | rest] when is_alphanumeric(c) ->
        add_string(scanner, rest, [c | agg])

      [?\n | rest] ->
        add_string(scanner, rest, agg)

      [?" | rest] ->
        scanner
        |> add_string_token(to_string_literal(agg))
        |> scan(rest)
    end
  end

  @spec add_string_token(Exlox.Scanner.t(), any()) :: Exlox.Scanner.t()
  def add_string_token(scanner, literal) do
    %Scanner{scanner | tokens: [Token.new(:string, scanner.line, literal) | scanner.tokens]}
  end

  def add_number_token(scanner, literal) do
    %Scanner{scanner | tokens: [Token.new(:number, scanner.line, literal) | scanner.tokens]}
  end

  @spec add_single_char_token(Exlox.Scanner.t(), any(), any()) :: {:error, any()} | {:ok, list()}
  def add_single_char_token(scanner, char, rest) do
    scanner
    |> add_token(Map.get(@single_char_token_map, char))
    |> scan(rest)
  end

  @spec add_token(Exlox.Scanner.t(), atom()) :: Exlox.Scanner.t()
  def add_token(scanner, token_type) do
    %Scanner{scanner | tokens: [Token.new(token_type, scanner.line) | scanner.tokens]}
  end

  @spec add_token(Exlox.Scanner.t(), any(), any()) :: Exlox.Scanner.t()
  def add_token(scanner, token_type, literal) do
    %Scanner{scanner | tokens: [Token.new(token_type, scanner.line, literal) | scanner.tokens]}
  end

  @spec add_error(Exlox.Scanner.t(), any()) :: {:error, any()} | {:ok, list()}
  def add_error(scanner, err_msg, char \\ nil) do
    %Scanner{scanner | errors: [ScanError.new(err_msg, scanner.line, char) | scanner.errors]}
    |> scan([])
  end

  @spec increase_line(Scanner.t()) :: Scanner.t()
  def increase_line(scanner) do
    %Scanner{scanner | line: scanner.line + 1}
  end

  @spec to_string_literal(any()) :: binary()
  def to_string_literal(chars), do: chars |> Enum.reverse() |> List.to_string()

  @spec to_number_literal(charlist(), boolean()) :: float()
  def to_number_literal(chars, has_dot) do
    if has_dot do
      chars
    else
      [?0, ?. | chars]
    end
    |> Enum.reverse()
    |> List.to_float()
  end
end
