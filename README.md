# thank-you-stars

A tool for starring GitHub repositories.
It detects dependent libraries which are hosted on GitHub via `mix.deps` file,
and stars the repositories all at once.

## Setup

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `thank_you_stars` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thank_you_stars, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/thank_you_stars](https://hexdocs.pm/thank_you_stars).

## Usage

Run `mix thank_you_stars` in the root directory of your project.
Then it scans the `mix.deps` and scrape the Hex.pm,
stars your dependent libraries if they are hosted on GitHub.

```console
$  mix thank_you_stars
Starred! https://github.com/certifi/erlang-certifi
Starred! https://github.com/talentdeficit/exjsx
Starred! https://github.com/philss/floki
Starred! https://github.com/benoitc/hackney
Starred! https://github.com/edgurgel/httpoison
Starred! https://github.com/benoitc/erlang-idna
Starred! https://github.com/talentdeficit/jsx
Starred! https://github.com/benoitc/erlang-metrics
Starred! https://github.com/benoitc/mimerl
Starred! https://github.com/mochi/mochiweb
Starred! https://github.com/devinus/poison
Starred! https://github.com/deadtrickster/ssl_verify_fun.erl
Starred! https://github.com/edgurgel/tentacat
Starred! https://github.com/benoitc/unicode_util_compat
```

## Acknowledgement

This tool is greatly inspired by
[teppeis's JavaScript implementation](https://github.com/teppeis/thank-you-stars) and
[y-taka-23's Haskell implementation](https://github.com/y-taka-23/thank-you-stars).
