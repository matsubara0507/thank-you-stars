defmodule ThankYouStars.Result do
  def success(v), do: {:ok, v}

  def failure(v), do: {:error, v}

  def map({:ok, v}, f), do: success(f.(v))
  def map(err = {:error, _}, _), do: err

  def and_then({:ok, v}, f), do: f.(v)
  def and_then(err = {:error, _}, _), do: err

  def map_error({:error, e}, f), do: failure(f.(e))
  def map_error(r = {:ok, _}, _), do: r
end
