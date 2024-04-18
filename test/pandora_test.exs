defmodule PandoraTest do
  use ExUnit.Case
  doctest Pandora

  test "greets the world" do
    assert Pandora.hello() == :world
  end
end
