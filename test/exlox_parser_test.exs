defmodule ExloxParserTest do
  alias ExloxParserTest.TestingCase
  alias Exlox.Parser
  alias Exlox.Scanner
  alias Exlox.Expr
  alias Exlox.Expr.{Literal, Grouping, Unary, Binary}
  alias Parser
  use ExUnit.Case
  doctest Exlox.Parser

  @tag primary: true
  test "parsing primary" do
    {:ok, tokens} = Scanner.scan_tokens("1")
    assert Parser.parse_primary(tokens) == {%Literal{value: 1.0}, []}

    {:ok, tokens} = Scanner.scan_tokens("(1)")
    assert Parser.parse_primary(tokens) == {%Grouping{expr: %Literal{value: 1.0}}, []}
  end

  @tag unary: true
  test "parsing unary" do
    assert Parser.parse_unary(tokenize("(1)")) == {%Grouping{expr: %Literal{value: 1.0}}, []}

    assert Parser.parse_unary(tokenize("-1")) ==
             {%Unary{prefix: :negative, expr: %Literal{value: 1.0}}, []}

    assert Parser.parse_unary(tokenize("!1")) ==
             {%Unary{prefix: :not, expr: %Literal{value: 1.0}}, []}

    assert Parser.parse_unary(tokenize("!!1")) ==
             {%Unary{prefix: :not, expr: %Unary{prefix: :not, expr: %Literal{value: 1.0}}}, []}

    assert Parser.parse_unary(tokenize("!!(1)")) ==
             {%Unary{
                prefix: :not,
                expr: %Unary{prefix: :not, expr: %Grouping{expr: %Literal{value: 1.0}}}
              }, []}
  end

  @tag factor: true
  test "parsing factor" do
    assert Parser.parse_factor(tokenize("1")) == {%Literal{value: 1.0}, []}

    assert Parser.parse_factor(tokenize("!!(1)")) ==
             {%Unary{
                prefix: :not,
                expr: %Unary{prefix: :not, expr: %Grouping{expr: %Literal{value: 1.0}}}
              }, []}

    assert Parser.parse_factor(tokenize("2 / 2")) ==
             {%Binary{
                left: %Literal{value: 2.0},
                operator: :div,
                right: %Literal{value: 2.0}
              }, []}

    assert Parser.parse_factor(tokenize("2 * 2")) ==
             {%Binary{
                left: %Literal{value: 2.0},
                operator: :mul,
                right: %Literal{value: 2.0}
              }, []}

    assert Parser.parse_factor(tokenize("2 * 2 * 2")) ==
             {%Binary{
                left: %Binary{
                  left: %Literal{value: 2},
                  operator: :mul,
                  right: %Literal{value: 2}
                },
                operator: :mul,
                right: %Literal{value: 2}
              }, []}

    assert Parser.parse_factor(tokenize("2 * 2 * 2 / 2")) == {
             %Binary{
               left: %Binary{
                 left: %Binary{
                   left: %Literal{value: 2.0},
                   right: %Literal{value: 2.0},
                   operator: :mul
                 },
                 right: %Literal{value: 2.0},
                 operator: :mul
               },
               right: %Literal{value: 2.0},
               operator: :div
             },
             []
           }
  end

  @tag term: true
  test "parse term" do
    assert Parser.parse_term(tokenize("1 - 1")) == {
      %Binary{
        left: %Literal{value: 1.0},
        operator: :sub,
        right: %Literal{value: 1.0}
      }, []
    }

    assert Parser.parse_term(tokenize("10 - 2 * 3")) == {
      %Binary{
        left: %Literal{value: 10.0},
        operator: :sub,
        right: %Binary{
          left: %Literal{value: 2.0},
          operator: :mul,
          right: %Literal{value: 3.0}
        }
      }, []
    }

    Parser.parse_term(tokenize("3 - 2 + 1")) == {
      %Binary{
        left: %Binary{
          left: %Literal{value: 3.0},
          operator: :sub,
          right: %Literal{value: 2.0}
        },
        operator: :add,
        right: %Literal{value: 1.0}
      }, []
    }

    Parser.parse_term(tokenize("3 - (2 + 1)")) == {
      %Binary{
        left: %Literal{value: 3.0},
        operator: :sub,
        right: %Grouping{expr: %Binary{left: 2.0, operator: :add, right: 1.0}}
      }, []
    }
  end

  def tokenize(input) do
    case Scanner.scan_tokens(input) do
      {:ok, tokens} -> tokens
      {:error, err} -> err
    end
  end
end
