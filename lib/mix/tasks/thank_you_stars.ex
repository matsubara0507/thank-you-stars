defmodule Mix.Tasks.ThankYouStars do
  use Mix.Task

  @shortdoc "thank you stars !"

  def run(_args) do
    Mix.Task.run("app.start")

    case ThankYouStars.load_token() do
      {:ok, token} -> thank_you_stars(token)
      {:error, emessage} -> IO.puts(emessage)
    end
  end

  defp thank_you_stars(token) do
    ThankYouStars.load_deps_packages()
    |> Enum.map(&(ThankYouStars.star_package(&1, token) |> IO.puts()))
  end
end
