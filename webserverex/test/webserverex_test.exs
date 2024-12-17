defmodule WebserverexTest do
  use ExUnit.Case
  doctest Webserverex

  test "greets the world" do
    assert Webserverex.hello() == :world
  end
end
