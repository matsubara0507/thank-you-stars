defmodule Mix.Tasks.ThankYouStars do
  use Mix.Task
  require OK
  import OK, only: ["~>>": 2]

  @shortdoc "thank you stars !"

  def run(_args) do
    Mix.Task.run "app.start"

    OK.try do
      token <- load_token()
    after
      client = Tentacat.Client.new(%{access_token: token})
      ThankYouStars.load_deps_packages
        |> Enum.map(&(ThankYouStars.star_package(&1, client) |> IO.puts()))
    rescue
      emessage -> IO.puts emessage
    end
  end

  defp load_token do
    File.read(token_path())
      ~>> Poison.decode
      ~>> Map.fetch("token")
  end

  defp token_path,
    do: Path.join [System.user_home, ".thank-you-stars.json"]
end
