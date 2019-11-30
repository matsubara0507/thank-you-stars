defmodule ThankYouStars do
  @moduledoc """
  Helper functions for thank_you_stars task
  """

  @doc """
  load github api token from "$HOME/.thank_you_stars.json" file.
  format is `{ "token": "SET_YOUR_TOKEN_HERE" }` .
  """
  @spec load_token() :: binary
  def load_token do
    File.read(token_path())
    |> and_then(&poison_decode(&1))
    |> and_then(&Map.fetch(&1, "token"))
  end

  defp token_path,
    do: Path.join([System.user_home(), ".thank-you-stars.json"])

  defp poison_decode(str) do
    case Poison.decode(str) do
      {:error, _} -> {:error, :invalid}
      other -> other
    end
  end

  @doc """
  load dependency packages from mix.exs.
  """
  @spec load_deps_packages() :: [binary]
  def load_deps_packages do
    Mix.Project.config()
    |> Keyword.get(:deps)
    |> Enum.map(&(Tuple.to_list(&1) |> List.first()))
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  star package's GitHub repository.
  """
  @spec star_package(package_name :: binary, token :: binary) :: binary
  def star_package(package_name, token) do
    fetch_package_github_url(package_name)
    |> and_then(&star_github_package(&1, token))
    |> case do
      {:ok, url} -> "Starred! #{url}"
      {:error, url} -> "Error    #{url}"
    end
  end

  @doc """
  fetch github url of package from `hex.pm/api/packages` .
  """
  @spec fetch_package_github_url(package_name :: binary) :: binary
  def fetch_package_github_url(package_name) do
    HTTPoison.get("https://hex.pm/api/packages/#{package_name}")
    |> and_then(&map_get_with_ok(&1, :body))
    |> and_then(&poison_decode(&1))
    |> and_then(&map_get_with_ok(&1, "meta"))
    |> and_then(&map_get_with_ok(&1, "links"))
    |> and_then(&github_url(&1))
    |> case do
      {:error, _} -> {:error, package_name}
      ok -> ok
    end
  end

  @doc """
  get github url from json.
  field name is `GitHub`, `Github` or `github`.
  """
  @spec github_url(links :: map) :: {:ok, binary} | {:error, nil}
  def github_url(links) do
    ["GitHub", "Github", "github"]
    |> Enum.map(&Map.get(links, &1))
    |> Enum.filter(&(!is_nil(&1)))
    |> case do
      [] -> {:error, nil}
      [link | _] -> {:ok, link}
    end
  end

  defp map_get_with_ok(map, key) do
    case Map.get(map, key) do
      nil -> {:error, {:undefined_key, key}}
      value -> {:ok, value}
    end
  end

  @doc """
  star package's GitHub repository using GitHub API.
  """
  @spec star_github_package(
          url :: binary,
          token :: binary
        ) :: {:ok, binary} | {:error, binary}
  def star_github_package(url, token) do
    URI.parse(url)
    |> Map.get(:path, "")
    |> (&put_github_api("user/starred#{&1}", token)).()
    |> and_then(&map_get_with_ok(&1, :status_code))
    |> case do
      {:ok, 204} -> {:ok, url}
      _ -> {:error, url}
    end
  end

  defp put_github_api(path, token) do
    headers = [{"Authorization", "token #{token}"}]
    HTTPoison.put("https://api.github.com/#{path}", "", headers)
  end

  defp and_then({:ok, v}, f), do: f.(v)
  defp and_then(err = {:error, _}, _), do: err
end
