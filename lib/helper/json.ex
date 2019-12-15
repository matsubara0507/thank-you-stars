defmodule ThankYouStars.JSON do
  alias ThankYouStars.Result, as: Result

  def decode(str) do
    init_stat(str)
    |> match_element()
    |> case do
      {:ok, %{rest: "", result: result}} -> Result.success(result)
      {_, %{rest: rest}} -> Result.failure(rest)
    end
  end

  # Functions for Parser State

  defp init_stat(str), do: %{rest: str, result: %{}}

  defp update_stat(stat, :rest, v), do: Result.success(Map.put(stat, :rest, v))
  defp update_stat(stat, :result, v), do: Result.success(Map.put(stat, :result, v))
  defp update_stat(stat, _, _), do: Result.failure(stat)

  defp modify_stat(stat, :rest, f), do: Result.success(Map.update(stat, :rest, "", f))
  defp modify_stat(stat, :result, f), do: Result.success(Map.update(stat, :result, %{}, f))
  defp modify_stat(stat, _, _), do: Result.failure(stat)

  # Parsers

  defp match_value(%{rest: "true" <> rest}), do: Result.success(%{result: true, rest: rest})
  defp match_value(%{rest: "false" <> rest}), do: Result.success(%{result: false, rest: rest})
  defp match_value(%{rest: "null" <> rest}), do: Result.success(%{result: nil, rest: rest})
  defp match_value(stat = %{rest: "\"" <> _}), do: match_string(stat)
  defp match_value(stat = %{rest: "[" <> _}), do: match_array(stat)
  defp match_value(stat = %{rest: "{" <> _}), do: match_object(stat)
  defp match_value(stat), do: match_number(stat)

  defp match_object(stat) do
    match_left_par(stat)
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&update_stat(&1, :result, %{}))
    |> Result.and_then(&parse_when_unmatch_by(&1, "}", fn s -> match_members(s) end))
    |> Result.and_then(&match_right_par(&1))
  end

  defp match_members(stat) do
    match_member(stat)
    |> Result.and_then(&match_members_tail(&1))
  end

  defp match_members_tail(stat = %{rest: "," <> rest}) do
    update_stat(stat, :rest, rest)
    |> Result.and_then(&match_members(&1))
  end

  defp match_members_tail(stat), do: Result.success(stat)

  defp match_member(stat = %{result: prev}) do
    case match_string(trim_leading(stat)) do
      {:error, stat} ->
        Result.failure(stat)

      {:ok, stat = %{result: key}} ->
        trim_leading(stat)
        |> match_colon()
        |> Result.and_then(&match_element(&1))
        |> Result.and_then(&modify_stat(&1, :result, fn v -> Map.put(prev, key, v) end))
    end
  end

  defp match_array(stat) do
    match_left_square(stat)
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&update_stat(&1, :result, []))
    |> Result.and_then(&parse_when_unmatch_by(&1, "]", fn s -> match_elements(s) end))
    |> Result.and_then(&match_right_square(&1))
  end

  defp match_elements(stat = %{result: prev}) do
    match_element(stat)
    |> Result.and_then(&modify_stat(&1, :result, fn v -> prev ++ [v] end))
    |> Result.and_then(&match_elements_tail(&1))
  end

  defp match_elements_tail(stat = %{rest: "," <> rest}) do
    update_stat(stat, :rest, rest)
    |> Result.and_then(&match_elements(&1))
  end

  defp match_elements_tail(stat), do: Result.success(stat)

  defp match_element(stat) do
    trim_leading(stat)
    |> match_value()
    |> Result.map(&trim_leading(&1))
  end

  defp match_string(stat) do
    match_double_quote(stat)
    |> Result.and_then(&update_stat(&1, :result, ""))
    |> Result.and_then(&match_characters(&1))
    |> Result.and_then(&match_double_quote(&1))
  end

  defp match_characters(stat = %{rest: ""}), do: Result.success(stat)
  defp match_characters(stat = %{rest: "\"" <> _}), do: Result.success(stat)

  defp match_characters(stat) do
    parse_when_unmatch_by(stat, "\\", &match_noescape_characters(&1))
    |> Result.and_then(&match_escape(&1))
    |> Result.and_then(&match_characters(&1))
  end

  defp match_escape(%{rest: "\\\"" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\""}, :rest, rest)

  defp match_escape(%{rest: "\\\\" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\\"}, :rest, rest)

  defp match_escape(%{rest: "\\\/" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\/"}, :rest, rest)

  defp match_escape(%{rest: "\\b" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\b"}, :rest, rest)

  defp match_escape(%{rest: "\\f" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\f"}, :rest, rest)

  defp match_escape(%{rest: "\\n" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\n"}, :rest, rest)

  defp match_escape(%{rest: "\\r" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\r"}, :rest, rest)

  defp match_escape(%{rest: "\\t" <> rest, result: prev}),
    do: update_stat(%{result: prev <> "\t"}, :rest, rest)

  defp match_escape(stat = %{rest: "\\u" <> rest, result: prev}) do
    case Regex.named_captures(~r/(?<body>[\dA-Fa-f]{4,4})(?<rest>.*)/s, rest) do
      %{"body" => body, "rest" => rest} ->
        case hex_to_string(body) do
          nil -> Result.failure(stat)
          hex -> update_stat(%{result: prev <> hex}, :rest, rest)
        end

      _ ->
        Result.failure(stat)
    end
  end

  defp match_escape(stat = %{rest: "\\" <> _}), do: Result.failure(stat)
  defp match_escape(stat), do: Result.success(stat)

  defp hex_to_string(str) do
    try do
      {hex, _} = Integer.parse(str, 16)
      <<hex::utf8>>
    rescue
      _ -> nil
    end
  end

  defp match_noescape_characters(stat = %{rest: "\n" <> _}), do: Result.failure(stat)
  defp match_noescape_characters(stat = %{rest: "\t" <> _}), do: Result.failure(stat)
  defp match_noescape_characters(stat = %{rest: "\u0000" <> _}), do: Result.failure(stat)

  defp match_noescape_characters(stat = %{result: prev}) do
    %{"body" => body, "rest" => rest} =
      Regex.named_captures(~r/(?<body>[^\\\"\n\x00\t]*)(?<rest>.*)/s, stat[:rest])

    update_stat(%{result: prev <> body}, :rest, rest)
  end

  defp match_number(stat) do
    {value, rest} = compile_number(stat[:rest])

    case value do
      nil ->
        Result.failure(stat)

      _ ->
        Map.put(stat, :result, value)
        |> Map.put(:rest, rest)
        |> Result.success()
    end
  end

  # ToDo: exponent
  def compile_number(str) do
    %{"minus" => minus, "digit" => digit, "frac" => frac, "exp" => exp, "rest" => rest} =
      Regex.named_captures(
        ~r/(?<minus>-?)(?<digit>[[:digit:]]*)(?<frac>\.?[[:digit:]]*)(?<exp>[eE]?[-+]?[[:digit:]]*)(?<rest>.*)/s,
        str
      )

    value =
      case {digit, frac, exp} do
        {"", _, _} ->
          nil

        {"0" <> num, "", ""} when num != "" ->
          nil

        {_, "." <> num, _} when num == "" ->
          nil

        {_, _, "e" <> num} when num == "" ->
          nil

        {_, _, "E" <> num} when num == "" ->
          nil

        {_, "", ""} ->
          case Integer.parse(minus <> digit) do
            {num, ""} -> num
            _ -> nil
          end

        _ ->
          case Float.parse(minus <> digit <> frac <> exp) do
            {num, ""} -> num
            _ -> nil
          end
      end

    {value, rest}
  end

  # Helper Parsers

  defp match_char_by(c, stat) do
    case String.split(stat[:rest], "", parts: 3) do
      ["", ^c, rest] -> Result.success(Map.put(stat, :rest, rest))
      _ -> Result.failure(stat)
    end
  end

  defp match_left_par(stat), do: match_char_by("{", stat)
  defp match_right_par(stat), do: match_char_by("}", stat)
  defp match_left_square(stat), do: match_char_by("[", stat)
  defp match_right_square(stat), do: match_char_by("]", stat)
  defp match_colon(stat), do: match_char_by(":", stat)
  defp match_double_quote(stat), do: match_char_by("\"", stat)

  defp parse_when_unmatch_by(stat, c, f) do
    case String.split(stat[:rest], "", parts: 3) do
      ["", ^c, _] -> Result.success(stat)
      _ -> f.(stat)
    end
  end

  defp trim_leading(stat), do: Map.update(stat, :rest, "", &String.trim_leading(&1))
end
