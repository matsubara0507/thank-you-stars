defmodule ThankYouStars do
  @moduledoc """
  Helper functions for thank_you_stars task
  """

  alias ThankYouStars.Result, as: Result
  alias ThankYouStars.JSON, as: JSON

  @doc """
  load github api token from "$HOME/.thank_you_stars.json" file.
  format is `{ "token": "SET_YOUR_TOKEN_HERE" }` .
  """
  @spec load_token() :: binary
  def load_token do
    File.read(token_path())
    |> Result.and_then(&JSON.decode(&1))
    |> Result.and_then(&Map.fetch(&1, "token"))
  end

  defp token_path,
    do: Path.join([System.user_home(), ".thank-you-stars.json"])

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
    |> Result.and_then(&star_github_package(&1, token))
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
    |> Result.and_then(&map_get_with_ok(&1, :body))
    |> Result.and_then(&JSON.decode(&1))
    |> Result.and_then(&map_get_with_ok(&1, "meta"))
    |> Result.and_then(&map_get_with_ok(&1, "links"))
    |> Result.and_then(&github_url(&1))
    |> case do
      {:error, _} -> Result.failure(package_name)
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
      [] -> Result.failure(nil)
      [link | _] -> Result.success(link)
    end
  end

  defp map_get_with_ok(map, key) do
    case Map.get(map, key) do
      nil -> Result.failure({:undefined_key, key})
      value -> Result.success(value)
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
    |> Result.and_then(&map_get_with_ok(&1, :status_code))
    |> case do
      {:ok, 204} -> Result.success(url)
      _ -> Result.failure(url)
    end
  end

  defp put_github_api(path, token) do
    headers = [{"Authorization", "token #{token}"}]
    HTTPoison.put("https://api.github.com/#{path}", "", headers)
  end
end
