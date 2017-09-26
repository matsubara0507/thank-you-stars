defmodule ThankYouStarsTest do
  use ExUnit.Case
  doctest ThankYouStars

  test "greets the world" do
    assert ThankYouStars.hello() == :world
  end
end
