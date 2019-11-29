defmodule Mix.Tasks.ThankYouStars do
  use Mix.Task
  require OK

  @shortdoc "thank you stars !"

  def run(_args) do
    Mix.Task.run("app.start")

    OK.try do
      token <- ThankYouStars.load_token()
    after
      client = Tentacat.Client.new(%{access_token: token})

      ThankYouStars.load_deps_packages()
      |> Enum.map(&(ThankYouStars.star_package(&1, client) |> IO.puts()))
    rescue
      emessage -> IO.puts(emessage)
    end
  end
end
