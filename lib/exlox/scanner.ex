defmodule Exlox.Scanner do
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
        add_token(scanner, ?(, rest)

      [?) | rest] ->
        add_token(scanner, ?), rest)

      [?{ | rest] ->
        add_token(scanner, ?{, rest)

      [?} | rest] ->
        add_token(scanner, ?}, rest)

      [?, | rest] ->
        add_token(scanner, ?,, rest)

      [?., c | _] when is_digit(c) ->
        add_number(scanner, text, [], 0)

      [?. | rest] ->
        add_token(scanner, ?., rest)

      [?- | rest] ->
        add_token(scanner, ?-, rest)

      [?+ | rest] ->
        add_token(scanner, ?+, rest)

      [?; | rest] ->
        add_token(scanner, ?;, rest)

      [?* | rest] ->
        add_token(scanner, ?*, rest)

      [?!, ?= | rest] ->
        scanner |> add_token(:bang_equal) |> scan(rest)

      [?! | rest] ->
        add_token(scanner, ?!, rest)

      [?>, ?= | rest] ->
        scanner |> add_token(:greater_equal) |> scan(rest)

      [?> | rest] ->
        add_token(scanner, ?>, rest)

      [?<, ?= | rest] ->
        scanner |> add_token(:less_equal) |> scan(rest)

      [?< | rest] ->
        add_token(scanner, ?<, rest)

      [?=, ?= | rest] ->
        scanner |> add_token(:equal_equal) |> scan(rest)

      [?= | rest] ->
        add_token(scanner, ?=, rest)

      [?/, ?/ | rest] ->
        rest
        |> Enum.drop_while(fn c -> c != ?\n end)
        |> then(fn remain -> scan(scanner, remain) end)

      [?/ | rest] ->
        add_token(scanner, ?/, rest)

      [?\n | rest] ->
        scanner |> increase_line() |> scan(rest)

      [?" | rest] ->
        add_string(scanner, rest, [])

      [c | _] when is_digit(c) ->
        add_number(scanner, text, [], 0)

      [c | rest] when is_whitespace(c) ->
        scan(scanner, rest)

      _ ->
        add_error(scanner, "unexpected character")
    end
  end

  def add_number(scanner, [], agg, num_of_dot) do
    literal =
      if(num_of_dot > 0, do: agg, else: [?0, ?. | agg])
      |> Enum.reverse()
      |> List.to_float()

    scanner
    |> add_number_token(literal)
    |> scan([])
  end

  def add_number(scanner, [?., c | _], [], 0) when is_digit(c) do
    add_error(scanner, "unexpected character")
  end

  def add_number(scanner, [?.], _, _), do: add_error(scanner, "unexpected character")

  def add_number(scanner, chars, agg, num_of_dot) do
    case chars do
      [c | rest] when is_digit(c) ->
        add_number(scanner, rest, [c | agg], num_of_dot)

      [?., d | rest] when is_digit(d) ->
        add_number(scanner, rest, [d, ?. | agg], num_of_dot + 1)

      [?\n | rest] ->
        literal =
          if(num_of_dot > 0, do: agg, else: [?0 | [?. | agg]])
          |> Enum.reverse()
          |> List.to_float()

        scanner
        |> add_number_token(literal)
        |> increase_line()
        |> scan(rest)
    end
  end

  def add_string(scanner, [], _agg) do
    add_error(scanner, "unterminated string")
  end

  def add_string(scanner, chars, agg) do
    case chars do
      [c | rest] when is_alphanumeric(c) ->
        add_string(scanner, rest, [c | agg])

      [?\n | rest] ->
        add_string(scanner, rest, agg)

      [?" | rest] ->
        literal = agg |> Enum.reverse() |> List.to_string()

        scanner
        |> add_string_token(literal)
        |> scan(rest)
    end
  end

  def add_string_token(scanner, literal) do
    %Scanner{scanner | tokens: [Token.new(:string, scanner.line, literal) | scanner.tokens]}
  end

  def add_number_token(scanner, literal) do
    %Scanner{scanner | tokens: [Token.new(:number, scanner.line, literal) | scanner.tokens]}
  end

  def add_token(scanner, char, rest) do
    scanner
    |> add_token(Map.get(@single_char_token_map, char))
    |> scan(rest)
  end

  @spec add_token(Exlox.Scanner.t(), atom()) :: Exlox.Scanner.t()
  def add_token(scanner, token_type) do
    %Scanner{scanner | tokens: [Token.new(token_type, scanner.line) | scanner.tokens]}
  end

  @spec add_error(Scanner.t(), String.t()) :: Scanner.t()
  def add_error(scanner, err_msg) do
    %Scanner{scanner | errors: [err_msg | scanner.errors]}
    |> scan([])
  end

  @spec increase_line(Scanner.t()) :: Scanner.t()
  def increase_line(scanner) do
    %Scanner{scanner | line: scanner.line + 1}
  end
end
