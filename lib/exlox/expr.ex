defmodule Exlox.Expr do
  alias __MODULE__

  @type t ::
          Expr.Binary.t()
          | Expr.Literal.t()
          | Expr.Unary.t()
          | Expr.Grouping.t()

  defmodule Binary do
    @type operator :: :not_eq | :eq | :gt | :gt_eq | :lt | :lt_eq | :sub | :add | :div | :mul
    @type t :: %Binary{
            left: Expr.t(),
            operator: operator(),
            right: Expr.t(),
            line: non_neg_integer()
          }

    @enforce_keys [:left, :operator, :right, :line]
    defstruct [:left, :operator, :right, :line]

    defimpl Exlox.Print do
      alias Exlox.Print
      def ast_print(expr) do
        "(#{operator_to_string(expr.operator)} #{Print.ast_print(expr.left)} #{Print.ast_print(expr.right)})"
      end

      def operator_to_string(op) do
        case op do
          :not_eq -> "!="
          :eq -> "="
          :gt -> ">"
          :gt_eq -> ">="
          :lt -> "<"
          :lt_eq -> "<="
          :sub -> "-"
          :add -> "+"
          :div -> "/"
          :mul -> "*"
        end
      end
    end
  end

  defmodule Literal do
    @type data :: String.t() | number() | true | false | nil
    @type t :: %Literal{value: data()}
    @enforce_keys [:value]
    defstruct [:value]

    defimpl Exlox.Print do
      def ast_print(expr) do
        "#{expr.value}"
      end
    end
  end

  defmodule Unary do
    @type unary_op :: :not | :negative

    @type t :: %Unary{
            prefix: unary_op(),
            expr: Expr.t()
          }

    @enforce_keys [:prefix, :expr]
    defstruct [:prefix, :expr]

    defimpl Exlox.Print  do
      def ast_print(expr) do
        prefix_s = case expr.prefix do
          :not -> "!"
          :negative -> "-"
        end

        "(#{prefix_s} #{Exlox.Print.ast_print(expr.expr)})"
      end
    end
  end

  defmodule Grouping do
    @type t :: %Grouping{expr: Expr.t()}

    @enforce_keys [:expr]
    defstruct [:expr]

    defimpl Exlox.Print  do
      def ast_print(expr) do
        "(group #{Exlox.Print.ast_print(expr.expr)})"
      end
    end
  end
end
