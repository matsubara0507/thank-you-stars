defmodule ThankYouStarsSpec do
  use ESpec
  import ThankYouStars

  before do
    packages = [
      {:espec, "~> 1.4.6", [only: :test]},
      {:phoenix, "~> 3.0"}
    ]

    allow(Mix.Project |> to(accept(:config, fn -> [deps: packages] end)))

    allow(
      HTTPoison
      |> to(
        accept(:get, fn
          "https://hex.pm/api/packages/espec" -> {:ok, %{body: shared.espec_hexpm_json}}
          "https://hex.pm/api/packages/phoenix" -> {:ok, %{body: shared.phoenix_hexpm_json}}
          _ -> {:ok, %{body: shared.not_found_hexpm_json}}
        end)
      )
    )

    allow(
      HTTPoison
      |> to(
        accept(:put, fn
          "https://api.github.com/user/starred/antonmi/espec",
          _,
          [{"Authorization", "token CORRECT_TOKEN"}] ->
            {:ok, %{status_code: 204, body: ""}}

          _, _, _ ->
            {:error, nil}
        end)
      )
    )

    {:shared, deps_packages: packages}
  end

  describe "load_token" do
    context "correct pattern" do
      let(
        json: """
        {
            "token": "XXX"
        }
        """
      )

      before(do: allow(File |> to(accept(:read, fn _ -> {:ok, json()} end))))
      it(do: expect(load_token() |> to(eq({:ok, "XXX"}))))
    end

    context "not found .thank-you-stars.json" do
      before(do: allow(File |> to(accept(:read, fn _ -> {:error, nil} end))))
      it(do: expect(load_token() |> to(eq({:error, nil}))))
    end

    context "no json" do
      before(do: allow(File |> to(accept(:read, fn _ -> {:ok, ""} end))))
      it(do: expect(load_token() |> to(eq({:error, :invalid}))))
    end

    context "not have token field" do
      let(
        json: """
        {
            "taken": "XXX"
        }
        """
      )

      before(do: allow(File |> to(accept(:read, fn _ -> {:ok, json()} end))))
      it(do: expect(load_token() |> to(eq(:error))))
    end
  end

  describe "load_deps_packages" do
    it(do: expect(load_deps_packages() |> to(eq(["espec", "phoenix"]))))
  end

  describe "star_package" do
    it "existed package in hex.pm and correct response" do
      expect(
        star_package("espec", "CORRECT_TOKEN")
        |> to(eq("Starred! https://github.com/antonmi/espec"))
      )
    end

    it "existed package in hex.pm and error response" do
      expect(
        star_package("espec", "")
        |> to(eq("Error    https://github.com/antonmi/espec"))
      )
    end

    it "not existed package in hex.pm and correct response" do
      expect(
        star_package("thank_you_stars", "CORRECT_TOKEN")
        |> to(eq("Error    thank_you_stars"))
      )
    end

    it "not existed package in hex.pm and error response" do
      expect(
        star_package("thank_you_stars", "")
        |> to(eq("Error    thank_you_stars"))
      )
    end
  end

  describe "fetch_package_github_url(package_name)" do
    it "existed package in hex.pm" do
      expect(
        fetch_package_github_url("espec")
        |> to(eq({:ok, "https://github.com/antonmi/espec"}))
      )
    end

    it "not existed package in hex.pm" do
      expect(
        fetch_package_github_url("thank_you_stars")
        |> to(eq({:error, "thank_you_stars"}))
      )
    end
  end

  describe "github_url(links)" do
    it "correct pattern with GitHub" do
      expect(
        github_url(%{"GitHub" => "https://github.com/antonmi/espec"})
        |> to(eq({:ok, "https://github.com/antonmi/espec"}))
      )
    end

    it "correct pattern with Github" do
      expect(
        github_url(%{"Github" => "https://github.com/antonmi/espec"})
        |> to(eq({:ok, "https://github.com/antonmi/espec"}))
      )
    end

    it "correct pattern with github" do
      expect(
        github_url(%{"github" => "https://github.com/antonmi/espec"})
        |> to(eq({:ok, "https://github.com/antonmi/espec"}))
      )
    end

    it "not have GitHub link" do
      expect(
        github_url(%{})
        |> to(eq({:error, nil}))
      )
    end
  end

  describe "star_github_package(url, client)" do
    let(url: "https://github.com/antonmi/espec")

    it "correct respponse" do
      expect(
        star_github_package(url(), "CORRECT_TOKEN")
        |> to(eq({:ok, url()}))
      )
    end

    it "error respponse" do
      expect(
        star_github_package(url(), "")
        |> to(eq({:error, url()}))
      )
    end
  end
end
