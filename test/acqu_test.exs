defmodule AcquTest do
  use ExUnit.Case
  doctest Acqu

  test "greets the world" do
    assert Acqu.hello() == :world
  end
end
