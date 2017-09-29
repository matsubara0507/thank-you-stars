# thank-you-stars

A tool for starring GitHub repositories.
It detects dependent libraries which are hosted on GitHub via `mix.deps` file,
and stars the repositories all at once.

## Setup

Add `thank_you_stars` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thank_you_stars, git: "https://github.com/matsubara0507/thank-you-stars.git", tag: "master"}
  ]
end
```

To star GitHub repositories, you have to get your personal access token.

1. Open https://github.com/settings/tokens and press "Generate new token."
1. Input the description and check only "public_repo" as a scope.
1. Save the token as `$HOME/.thank-you-stars.json`:

```json
{
    "token": "SET_YOUR_TOKEN_HERE"
}
```

## Usage

Run `mix thank_you_stars` in the root directory of your project.
Then it scans the `mix.deps` and scrape the Hex.pm,
stars your dependent libraries if they are hosted on GitHub.

```console
$  mix thank_you_stars
Starred! https://github.com/antonmi/espec
Starred! https://github.com/edgurgel/httpoison
Starred! https://github.com/CrowdHailer/OK
Starred! https://github.com/devinus/poison
Starred! https://github.com/edgurgel/tentacat
```

## Acknowledgement

This tool is greatly inspired by
[teppeis's JavaScript implementation](https://github.com/teppeis/thank-you-stars) and
[y-taka-23's Haskell implementation](https://github.com/y-taka-23/thank-you-stars).
