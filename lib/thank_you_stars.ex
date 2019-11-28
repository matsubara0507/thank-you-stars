defmodule ThankYouStars do
  @moduledoc """
  Helper functions for thank_you_stars task
  """
  require OK
  import OK, only: [~>>: 2]

  @doc """
  load github api token from "$HOME/.thank_you_stars.json" file.
  format is `{ "token": "SET_YOUR_TOKEN_HERE" }` .
  """
  @spec load_token() :: binary
  def load_token do
    File.read(token_path())
    ~>> poison_decode()
    ~>> Map.fetch("token")
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
  @spec star_package(package_name :: binary, client :: Tentacat.Client.t()) :: binary
  def star_package(package_name, client) do
    result =
      fetch_package_github_url(package_name)
      ~>> star_github_package(client)

    case result do
      {:ok, url} -> "Starred! #{url}"
      {:error, url} -> "Error    #{url}"
    end
  end

  @doc """
  fetch github url of package from `hex.pm/api/packages` .
  """
  @spec fetch_package_github_url(package_name :: binary) :: binary
  def fetch_package_github_url(package_name) do
    result =
      HTTPoison.get("https://hex.pm/api/packages/#{package_name}")
      ~>> map_get_with_ok(:body)
      ~>> poison_decode()
      ~>> map_get_with_ok("meta")
      ~>> map_get_with_ok("links")
      ~>> github_url()

    case result do
      {:error, _} -> OK.failure(package_name)
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
      [] -> OK.failure(nil)
      [link | _] -> OK.success(link)
    end
  end

  defp map_get_with_ok(map, key) do
    case Map.get(map, key) do
      nil -> OK.failure({:undefined_key, key})
      value -> OK.success(value)
    end
  end

  @doc """
  star package's GitHub repository using GitHub API.
  """
  @spec star_github_package(
          url :: binary,
          client :: Tentacat.Client.t()
        ) :: {:ok, binary} | {:error, binary}
  def star_github_package(url, client) do
    url
    |> URI.parse()
    |> Map.get(:path, "")
    |> (&Tentacat.put("user/starred#{&1}", client)).()
    |> case do
      {204, _, _} -> OK.success(url)
      _ -> OK.failure(url)
    end
  end
end
