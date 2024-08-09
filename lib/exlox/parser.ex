defmodule Exlox.Parser do
  alias Exlox.Expr.Binary
  alias Exlox.Expr.Unary
  alias Exlox.Expr.Grouping
  alias Exlox.Expr
  alias Exlox.Expr.Literal
  alias Exlox.Token
  alias __MODULE__

  @type t :: %Parser{
          # tokens: list(Token.t())
          expr: Expr
        }

  # @enforce_keys [:tokens]
  defstruct [:expr]

  def parse_expression(tokens) do
    parse_equality(tokens)
  end

  def parse_equality(tokens) do
    case parse_comparison(tokens) do
      {nil, rest} -> {nil, rest}
      {left_expr, rest} -> parse_equality_left(left_expr, rest)
    end
  end

  def parse_equality_left(left_expr, tokens) do
    case tokens do
      [%Token{type: t} | rest] when t in [:bang_equal, :equal_equal] ->
        case parse_comparison(rest) do
          {nil, _} ->
            {left_expr, tokens}

          {right_expr, rest} ->
            new_left = Binary.new_from_token(left_expr, right_expr, t)
            parse_equality_left(new_left, rest)
        end

      _ ->
        {left_expr, tokens}
    end
  end

  def parse_comparison(tokens) do
    case parse_term(tokens) do
      {nil, rest} -> {nil, rest}
      {left_expr, rest} -> parse_comparison_left(left_expr, rest)
    end
  end

  def parse_comparison_left(left_expr, tokens) do
    case tokens do
      [%Token{type: t} | rest] when t in [:greater_equal, :greater, :less, :less_equal] ->
        case parse_term(rest) do
          {nil, _} ->
            {left_expr, tokens}

          {right_expr, rest} ->
            new_left = Binary.new_from_token(left_expr, right_expr, t)
            parse_comparison_left(new_left, rest)
        end

      _ ->
        {left_expr, tokens}
    end
  end

  def parse_term(tokens) do
    case parse_factor(tokens) do
      {nil, rest} ->
        {nil, rest}

      {left_expr, rest} ->
        parse_term_left(left_expr, rest)
    end
  end

  def parse_term_left(left_expr, tokens) do
    case tokens do
      [%Token{type: t} | rest] when t in [:plus, :minus] ->
        case parse_factor(rest) do
          {nil, _} ->
            {left_expr, tokens}

          {right_expr, rest} ->
            new_left = Binary.new_from_token(left_expr, right_expr, t)
            parse_term_left(new_left, rest)
        end

      _ ->
        {left_expr, tokens}
    end
  end

  def parse_factor(tokens) do
    case parse_unary(tokens) do
      {nil, rest} ->
        {nil, rest}

      {left_expr, rest} ->
        parse_factor_left(left_expr, rest)
    end
  end

  # left here means left-associate. Eg: 2 * 2 * 2 => (2 * 2) * 2
  def parse_factor_left(left_expr, tokens) do
    # dbg({left_expr, tokens})

    case tokens do
      [%Token{type: t} | rest] when t in [:slash, :star] ->
        case parse_unary(rest) do
          {nil, _} ->
            {left_expr, tokens}

          {right_expr, rest} ->
            new_left = Binary.new_from_token(left_expr, right_expr, t)
            parse_factor_left(new_left, rest)
        end

      _ ->
        {left_expr, tokens}
    end
  end

  def parse_unary(tokens) do
    # dbg(tokens)

    case tokens do
      [%Token{type: type} | rest] when type in [:minus, :bang] ->
        {expr, rest2} = parse_unary(rest)
        {Unary.new_from_token(type, expr), rest2}

      _ ->
        parse_primary(tokens)
    end
  end

  def parse_primary([token | rest]) do
    # dbg({token, rest})

    case token.type do
      :number ->
        {Literal.new(token.literal), rest}

      :string ->
        {Literal.new(token.literal), rest}

      true ->
        {Literal.new(true), rest}

      false ->
        {Literal.new(false), rest}

      nil ->
        {Literal.new(nil), rest}

      :left_paren ->
        case parse_expression(rest) do
          {expr, [%Token{type: :right_paren} | the_rest]} -> {Grouping.new(expr), the_rest}
          _ -> {}
        end

      _ ->
        {nil, [token | rest]}
    end
  end

  defmodule Exlox.Parser.Error do
    defstruct [:msg, :line]

    def new(msg), do: %__MODULE__{msg: msg}
  end
end
