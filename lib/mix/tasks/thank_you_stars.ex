defmodule Mix.Tasks.ThankYouStars do
  use Mix.Task

  @shortdoc "thank you stars !"

  def run(_args) do
    Mix.Task.run "app.start"

    token = System.user_home
              |> (&(Path.join [&1, ".thank-you-stars.json"])).()
              |> File.read!()
              |> Poison.decode!()
              |> Map.get("token")

    client = Tentacat.Client.new(%{access_token: token})

    Mix.Project.deps_paths
      |> Map.keys()
      |> Stream.map(&Atom.to_string/1)
      |> Stream.flat_map(&scrape_package/1)
      |> Stream.map(&(star_package &1, client))
      |> Enum.map(&IO.puts/1)
  end

  defp scrape_package(package_name) do
    "https://hex.pm/packages/#{package_name}"
      |> HTTPoison.get!()
      |> Map.get(:body)
      |> Floki.find("ul.links")
      |> Floki.find("a")
      |> Enum.filter(&(String.downcase(Floki.text(&1)) == "github"))
      |> Floki.attribute("href")
  end

  defp star_package(url, client) do
    url
      |> URI.parse()
      |> Map.get(:path)
      |> (&(Tentacat.put "user/starred#{&1}", client)).()
      |> case do
           {204, _} -> "Starred! #{url}"
           _        -> "Error    #{url}"
         end
  end
end
