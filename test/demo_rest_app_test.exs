defmodule DemoRestAppTest do
  use ExUnit.Case
  doctest DemoRestApp

  test "greets the world" do
    assert DemoRestApp.hello() == :world
  end
end
