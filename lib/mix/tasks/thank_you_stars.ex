defmodule Mix.Tasks.ThankYouStars do
  use Mix.Task

  @shortdoc "thank you stars !"

  def run(_args) do
    Mix.Task.run("app.start")

    case ThankYouStars.load_token() do
      {:ok, token} -> thank_you_stars(Tentacat.Client.new(%{access_token: token}))
      {:error, emessage} -> IO.puts(emessage)
    end
  end

  defp thank_you_stars(client) do
    ThankYouStars.load_deps_packages()
    |> Enum.map(&(ThankYouStars.star_package(&1, client) |> IO.puts()))
  end
end
