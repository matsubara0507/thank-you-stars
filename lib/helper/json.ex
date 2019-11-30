defmodule ThankYouStars.JSON do
  alias ThankYouStars.Result, as: Result

  def decode(str) do
    match_object(%{rest: String.trim(str), result: %{}})
    |> case do
      {:ok, %{rest: "", result: result}} -> Result.success(result)
      {_, %{rest: rest}} -> Result.failure(rest)
    end
  end

  def match_object(stat) do
    match_left_par(stat)
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&match_object_body(&1))
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&match_right_par(&1))
  end

  def match_left_par(stat = %{rest: "{" <> rest}), do: Result.success(Map.put(stat, :rest, rest))
  def match_left_par(stat), do: Result.failure(stat)

  def match_right_par(stat = %{rest: "}" <> rest}),
    do: Result.success(Map.put(stat, :rest, rest))

  def match_right_par(stat), do: Result.failure(stat)

  def match_left_square(stat = %{rest: "[" <> rest}),
    do: Result.success(Map.put(stat, :rest, rest))

  def match_left_square(stat), do: Result.failure(stat)

  def match_right_square(stat = %{rest: "]" <> rest}),
    do: Result.success(Map.put(stat, :rest, rest))

  def match_right_square(stat), do: Result.failure(stat)

  def match_colon(stat = %{rest: ":" <> rest}), do: Result.success(Map.put(stat, :rest, rest))
  def match_colon(stat), do: Result.failure(stat)

  def match_double_quote(stat = %{rest: "\"" <> rest}),
    do: Result.success(Map.put(stat, :rest, rest))

  def match_double_quote(stat), do: Result.failure(stat)

  def match_object_body(stat = %{rest: "}" <> _}), do: Result.success(stat)

  def match_object_body(stat = %{result: prev}) do
    case match_string(stat) do
      {:error, stat} ->
        Result.failure(stat)

      {:ok, stat = %{result: key}} ->
        trim_leading(stat)
        |> match_colon()
        |> Result.and_then(&match_value(&1))
        |> Result.and_then(&put_to_result(prev, key, &1))
        |> Result.and_then(&match_object_body_tail(&1))
    end
  end

  def match_object_body_tail(stat = %{rest: "}" <> _}), do: Result.success(stat)

  def match_object_body_tail(stat = %{rest: "," <> rest}) do
    Map.put(stat, :rest, rest)
    |> trim_leading()
    |> match_object_body()
  end

  def match_object_body_tail(stat), do: Result.failure(stat)

  def match_string(stat) do
    match_double_quote(stat)
    |> Result.and_then(&match_string_body(&1))
    |> Result.and_then(&match_double_quote(&1))
  end

  def match_string_body(stat) do
    {value, rest} = compile_string(stat[:rest])

    Map.put(stat, :result, value)
    |> Map.put(:rest, rest)
    |> Result.success()
  end

  def compile_string(""), do: {"", ""}
  def compile_string(str = "\"" <> _), do: {"", str}

  def compile_string("\\" <> rest) do
    {body, rest} =
      case rest do
        "\"" <> rest ->
          {"\"", rest}

        "\\" <> rest ->
          {"\\", rest}

        "\/" <> rest ->
          {"\/", rest}

        "b" <> rest ->
          {"\b", rest}

        "f" <> rest ->
          {"\f", rest}

        "n" <> rest ->
          {"\n", rest}

        "r" <> rest ->
          {"\r", rest}

        "t" <> rest ->
          {"\t", rest}
          # "u" <> rest -> _ # ToDo
      end

    case compile_string(rest) do
      {"", rest} -> {body, rest}
      {next, rest} -> {body <> next, rest}
    end
  end

  def compile_string(str) do
    %{"body" => body, "rest" => rest} =
      Regex.named_captures(~r/(?<body>[^\\\"]*)(?<rest>.*)/s, str)

    case compile_string(rest) do
      {"", rest} -> {body, rest}
      {next, rest} -> {body <> next, rest}
    end
  end

  def match_value(stat) do
    trim_leading(stat)
    |> match_value_body()
    |> Result.map(&trim_leading(&1))
  end

  def match_value_body(stat = %{rest: "true" <> rest}) do
    Map.put(stat, :result, true)
    |> Map.put(:rest, rest)
    |> Result.success()
  end

  def match_value_body(stat = %{rest: "false" <> rest}) do
    Map.put(stat, :result, false)
    |> Map.put(:rest, rest)
    |> Result.success()
  end

  def match_value_body(stat = %{rest: "null" <> rest}) do
    Map.put(stat, :result, nil)
    |> Map.put(:rest, rest)
    |> Result.success()
  end

  def match_value_body(stat = %{rest: "\"" <> _}), do: match_string(stat)
  def match_value_body(stat = %{rest: "[" <> _}), do: match_array(stat)
  def match_value_body(stat = %{rest: "{" <> _}), do: match_object(Map.put(stat, :result, %{}))
  def match_value_body(stat), do: match_number(stat)

  def match_array(stat) do
    match_left_square(stat)
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&match_array_body(Map.put(&1, :result, [])))
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&match_right_square(&1))
  end

  def match_array_body(stat = %{rest: "]" <> _}), do: Result.success(stat)

  def match_array_body(stat = %{result: prev}) do
    match_value(stat)
    |> Result.and_then(&push_to_result(prev, &1))
    |> Result.map(&trim_leading(&1))
    |> Result.and_then(&match_array_body_tail(&1))
  end

  def match_array_body_tail(stat = %{rest: "]" <> _}), do: Result.success(stat)

  def match_array_body_tail(stat = %{rest: "," <> rest}),
    do: match_array_body(Map.put(stat, :rest, rest))

  def match_array_body_tail(stat), do: Result.failure(stat)

  def match_number(stat) do
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
    %{"minus" => minus, "digit" => digit, "frac" => frac, "rest" => rest} =
      Regex.named_captures(
        ~r/(?<minus>-?)(?<digit>[[:digit:]]*)(?<frac>\.?[[:digit:]]*)(?<rest>.*)/s,
        str
      )

    value =
      case {digit, frac} do
        {"", _} ->
          nil

        {"0" <> num, ""} when num == "" ->
          nil

        {_, "." <> num} when num == "" ->
          nil

        {_, ""} ->
          case Integer.parse(minus <> digit) do
            {num, ""} -> num
            _ -> nil
          end

        _ ->
          case Float.parse(minus <> digit <> frac) do
            {num, ""} -> num
            _ -> nil
          end
      end

    {value, rest}
  end

  def put_to_result(result, key, stat = %{result: value}) do
    Map.put(stat, :result, Map.put(result, key, value))
    |> Result.success()
  end

  def put_to_result(_, _, stat), do: Result.failure(stat)

  def push_to_result(result, stat = %{result: value}) do
    Map.put(stat, :result, result ++ [value])
    |> Result.success()
  end

  def push_to_result(_, stat), do: Result.failure(stat)

  def trim_leading(stat), do: Map.update(stat, :rest, "", &String.trim_leading(&1))
end
