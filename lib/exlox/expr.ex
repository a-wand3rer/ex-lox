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
            right: Expr.t()
          }

    @enforce_keys [:left, :operator, :right]
    defstruct [:left, :operator, :right]

    @operator_map %{
      :star => :mul,
      :slash => :div,
      :minus => :sub,
      :plus => :add,
      :greater => :gt,
      :greater_equal => :gt_eq,
      :less => :lt,
      :less_equal => :lt_eq,
      :bang_equal => :not_eq,
      :equal_equal => :eq
    }

    def new_from_token(left, right, operator) do
      %Binary{
        left: left,
        right: right,
        operator: Map.get(@operator_map, operator)
      }
    end

    defimpl Exlox.Print do
      alias Exlox.Print

      def ast_print(expr) do
        "(#{operator_to_string(expr.operator)} #{Print.ast_print(expr.left)} #{Print.ast_print(expr.right)})"
      end

      @spec operator_to_string(
              :add
              | :div
              | :eq
              | :gt
              | :gt_eq
              | :lt
              | :lt_eq
              | :mul
              | :not_eq
              | :sub
            ) :: nonempty_binary()
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

    def new(v), do: %Literal{value: v}

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

    @token_type_prefix_map %{
      :minus => :negative,
      :bang => :not
    }

    def new_from_token(type, expr),
      do: %Unary{prefix: Map.get(@token_type_prefix_map, type), expr: expr}

    defimpl Exlox.Print do
      def ast_print(expr) do
        prefix_s =
          case expr.prefix do
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

    def new(expr), do: %Grouping{expr: expr}

    defimpl Exlox.Print do
      def ast_print(expr) do
        "(group #{Exlox.Print.ast_print(expr.expr)})"
      end
    end
  end
end
