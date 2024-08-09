defmodule ExloxTest do
  use ExUnit.Case
  doctest Exlox

  test "greets the world" do
    assert Exlox.hello() == :world
  end
end
