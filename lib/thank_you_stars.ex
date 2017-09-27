defmodule ThankYouStars do
  @moduledoc """
  Helper functions for thank_you_stars task
  """
  require OK
  import OK, only: ["~>>": 2]

  def load_token do
    File.read(token_path())
      ~>> poison_decode()
      ~>> Map.fetch("token")
  end

  defp token_path,
    do: Path.join [System.user_home, ".thank-you-stars.json"]

  defp poison_decode(str) do
    case Poison.decode(str) do
      {:error, :invalid, _} -> {:error, :invalid}
      other -> other
    end
  end

  def load_deps_packages do
    Mix.Project.deps_paths
      |> Map.keys()
      |> Enum.map(&Atom.to_string/1)
  end

  def star_package(package_name, client) do
    result =
      fetch_package_github_url(package_name)
        ~>> star_github_package(client)
    case result do
      {:ok, url}    -> "Starred! #{url}"
      {:error, url} -> "Error    #{url}"
    end
  end

  def fetch_package_github_url(package_name) do
    OK.with do
      HTTPoison.get("https://hex.pm/packages/#{package_name}")
        ~>> scrape_github_url
    else
      _reson -> OK.failure(package_name)
    end
  end

  def scrape_github_url(http_response) do
    Map.get(http_response, :body, "")
      |> Floki.find("ul.links")
      |> Floki.find("a")
      |> Enum.filter(&github_url?/1)
      |> Floki.attribute("href")
      |> List.first()
      |> OK.required("GitHub URL is not scraped.")
  end

  def github_url?(html),
    do: Floki.text(html) |> String.downcase() |> String.equivalent?("github")

  def star_github_package(url, client) do
    url
      |> URI.parse()
      |> Map.get(:path, "")
      |> (&(Tentacat.put "user/starred#{&1}", client)).()
      |> case do
           {204, _} -> OK.success(url)
           _        -> OK.failure(url)
         end
  end
end
