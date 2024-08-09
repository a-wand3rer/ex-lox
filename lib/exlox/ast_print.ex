defprotocol Exlox.Print do
  alias Exlox.Expr
  @spec ast_print(Expr.t()) :: String.t()
  def ast_print(expr)
end

# defimpl Exlox.Print, for: Atom do
#   def ast_print(ex)
# end
