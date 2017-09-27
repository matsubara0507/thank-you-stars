defmodule ThankYouStarsSpec do
  use ESpec
  import ThankYouStars

  before do
    packages =
      [
        {:espec, "~> 1.4.6", [only: :test]},
        {:phoenix, "~> 3.0"}
      ]
    allow(Mix.Project).to accept(:config, fn -> [deps: packages] end)
    allow(HTTPoison).to accept(:get, fn
      "https://hex.pm/packages/espec" -> {:ok, %{body: shared.espec_hexpm_html}}
      "https://hex.pm/packages/phoenix" -> {:ok, %{body: shared.phoenix_hexpm_html}}
      _ -> {:ok, %{body: shared.not_found_hexpm_html}}
    end)
    allow(Tentacat).to accept(:put, fn
      (_, :correct) -> {204, nil}
      (_, :error)   -> {404, nil}
    end)
    {:shared, deps_packages: packages}
  end

  describe "load_token" do
    context "correct pattern" do
      let json:
        """
        {
            "token": "XXX"
        }
        """
      before do: allow(File).to accept(:read, fn _ -> {:ok, json()} end)
      it do: expect load_token() |> to(eq {:ok, "XXX"})
    end

    context "not found .thank-you-stars.json" do
      before do: allow(File).to accept(:read, fn _ -> {:error, nil} end)
      it do: expect load_token() |> to(eq {:error, nil})
    end

    context "no json" do
      before do: allow(File).to accept(:read, fn _ -> {:ok, ""} end)
      it do: expect load_token() |> to(eq {:error, :invalid})
    end

    context "not have token field" do
      let json:
        """
        {
            "taken": "XXX"
        }
        """
      before do: allow(File).to accept(:read, fn _ -> {:ok, json()} end)
      it do: expect load_token() |> to(eq :error)
    end
  end

  describe "load_deps_packages" do
    it do: expect load_deps_packages() |> to(eq ["espec", "phoenix"])
  end

  describe "star_package" do
    it "existed package in hex.pm and correct response" do
      expect star_package("espec", :correct)
        |> to(eq "Starred! https://github.com/antonmi/espec")
    end
    it "existed package in hex.pm and error response" do
      expect star_package("espec", :error)
        |> to(eq "Error    https://github.com/antonmi/espec")
    end
    it "not existed package in hex.pm and correct response" do
      expect star_package("thank_you_stars", :correct)
        |> to(eq "Error    thank_you_stars")
    end
    it "not existed package in hex.pm and error response" do
      expect star_package("thank_you_stars", :error)
        |> to(eq "Error    thank_you_stars")
    end
  end

  describe "fetch_package_github_url(package_name)" do
    it "existed package in hex.pm" do
      expect fetch_package_github_url("espec")
        |> to(eq {:ok, "https://github.com/antonmi/espec"})
    end
    it "not existed package in hex.pm" do
      expect fetch_package_github_url("thank_you_stars")
        |> to(eq {:error, "thank_you_stars"})
    end
  end

  describe "scrape_github_url(http_response)" do
    it "correct pattern" do
      expect scrape_github_url(%{body: shared.espec_hexpm_html})
        |> to(eq {:ok, "https://github.com/antonmi/espec"})
    end
    it "not found page" do
      expect scrape_github_url(%{body: shared.not_found_hexpm_html})
        |> to(eq {:error, "GitHub URL is not scraped."})
    end
    it "no body response" do
      expect scrape_github_url(%{})
        |> to(eq {:error, "GitHub URL is not scraped."})
    end
  end

  describe "github_url?(html)" do
    it "contain GitHub" do
      expect github_url?([{"a", [{"href", "http://github.com"}], ["GitHub"]}])
        |> to(be_true())
    end
    it "contain Github" do
      expect github_url?([{"a", [{"href", "http://github.com"}], ["Github"]}])
        |> to(be_true())
    end
    it "contain github" do
      expect github_url?([{"a", [{"href", "http://github.com"}], ["github"]}])
        |> to(be_true())
    end
    it "not contain" do
      expect github_url?([{"a", [{"href", "http://github.com"}], ["Hi"]}])
        |> to(be_false())
    end
  end

  describe "star_github_package(url, client)" do
    let url: "https://github.com/antonmi/espec"
    it "correct respponse" do
      expect star_github_package(url(), :correct)
        |> to(eq {:ok, url()})
    end
    it "error respponse" do
      expect star_github_package(url(), :error)
        |> to(eq {:error, url()})
    end
  end
end
