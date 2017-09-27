defmodule FlightAuth.CLI do
  def main(arguments) do
    {_opts, args, _} = OptionParser.parse(arguments)

    data = parse_env("FLIGHT_DATA")
    credential = parse_env("FLIGHT_CREDENTIAL")

    cols = %{
      "password" => "password",
    }

    case args do
      ["password-hash",   opts | _] -> opts |> parse_arg(cols) |> password_hash(data,credential)
      ["format-for-auth", opts | _] -> opts |> parse_arg(cols) |> format_for_auth(data,credential)
      ["sign",            opts | _] -> opts |> parse_arg(cols) |> sign(data,credential)
      ["renew",           opts | _] -> opts |> parse_arg(cols) |> renew(data,credential)
      ["verify",          opts | _] -> opts |> parse_arg(cols) |> verify(data,credential)

      _ -> "unknown command: #{arguments}" |> puts_error
    end
  end

  defp password_hash(opts,data,_credential) do
    kind = opts["kind"]
    salt = opts["salt"]
    password_col = opts["password"]

    data
    |> Enum.map(fn info ->
      info = case info["kind"] do
        ^kind -> info |> update_in(["properties",password_col], fn val ->
          case val do
            "" -> ""
            password -> password |> FlightAuth.password_hash(salt)
          end
        end)
        _ -> info
      end
      info
    end)
    |> puts_result
  end

  defp format_for_auth(opts,data,_credential) do
    salt = opts["salt"]
    password_col = opts["password"]

    %{ data | "conditions" => %{
      data["conditions"] | password_col => data["conditions"][password_col] |> FlightAuth.password_hash(salt)
    }}
    |> puts_result
  end

  defp sign(opts,data,_credential) do
    auth_key = opts["key"]
    password_col = opts["password"]
    require_cols = opts["require_cols"]

    now = DateTime.utc_now |> DateTime.to_iso8601
    data
    |> Map.delete(password_col)
    |> Map.put("signedAt", now)
    |> Map.put("renewedAt", now)
    |> sign_key(auth_key, require_cols)
  end

  defp renew(opts,_data,credential) do
    auth_key = opts["key"]
    require_cols = opts["require_cols"]
    verify = opts["verify"] || 0

    now = DateTime.utc_now |> DateTime.to_iso8601
    credential
    |> Map.delete("token")
    |> Map.put("renewedAt", now)
    |> sign_key(auth_key, require_cols, verify)
  end

  defp verify(opts,data,_credential) do
    auth_key = opts["key"]
    expire = opts["expire"] || 0

    case FlightAuth.verify(auth_key, expire, data["token"]) do
      {:ok,    credential} -> credential |> puts_result
      {:error, message}    -> message    |> puts_result(101)
    end
  end

  defp sign_key(data,auth_key,require_cols,verify) do
    case data["signedAt"] |> DateTime.from_iso8601 do
      {:ok, signed_at, _offset} ->
        if DateTime.utc_now |> DateTime.diff(signed_at) < verify do
          sign_key(data,auth_key,require_cols)
        else
          "signed_at expired: #{signed_at |> inspect}"
          |> puts_result(101)
        end
      {:error, message} ->
        "failed parse signed_at: #{message}"
        |> puts_result(101)
    end
  end
  defp sign_key(data,auth_key,require_cols) do
    case FlightAuth.sign(auth_key, data, require_cols) do
      {:ok, token} ->
        data
        |> Map.put("token", token)
        |> puts_result
      {:error, message} ->
        message
        |> puts_result(101)
    end
  end

  defp parse_env(key) do
    System.get_env(key)
    |> parse_json
  end
  defp parse_arg(json,defaults) do
    defaults
    |> Map.merge(
      json
      |> parse_json
    )
  end
  defp parse_json(json) do
    json
    |> case do
      nil -> %{}
      raw ->
        raw
        |> Poison.decode!
        |> case do
          nil -> %{}
          data -> data
        end
    end
  end

  defp puts_result(data) do
    IO.puts(data |> Poison.encode!)
  end
  defp puts_result(message,status) do
    IO.puts(message)
    System.halt(status)
  end
  defp puts_error(message) do
    IO.puts(:stderr, "#{__MODULE__}: [ERROR] #{message}")
    System.halt(1)
  end
end
