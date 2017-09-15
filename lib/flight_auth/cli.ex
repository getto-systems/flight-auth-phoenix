defmodule FlightAuth.CLI do
  def main(arguments) do
    {opts, args, _} = OptionParser.parse(arguments, strict: [
      password: :string,
      loginID: :string,
      role: :string,
      expire: :integer,
      verify: :integer,
    ])

    data = parse_data("FLIGHT_DATA")
    credential = parse_data("FLIGHT_CREDENTIAL")

    password_col = opts[:password] || "password"
    loginID_col = opts[:loginID] || "loginID"
    role_col = opts[:role] || "role"

    require_cols = [loginID_col, role_col]

    case args do
      ["password-hash", kind, salt | _] ->
        data |> Enum.reduce([], fn info, acc ->
          info = case info["kind"] do
            ^kind -> info |> update_in(["properties",password_col], fn val ->
              case val do
                "" -> ""
                password -> password |> FlightAuth.password_hash(salt)
              end
            end)
            _ -> info
          end
          [info | acc]
        end) |> Enum.reverse
        |> puts_result

      ["format-for-auth", salt | _] ->
        %{
          "key" => data["key"],
          "conditions" => %{
            password_col => data[password_col] |> FlightAuth.password_hash(salt),
          },
          "columns" => require_cols,
        }
        |> puts_result

      ["sign", auth_key | _] ->
        now = DateTime.utc_now |> DateTime.to_iso8601
        data
        |> Map.delete(password_col)
        |> Map.put("signedAt", now)
        |> Map.put("renewedAt", now)
        |> sign(auth_key, require_cols)

      ["renew", auth_key | _] ->
        now = DateTime.utc_now |> DateTime.to_iso8601
        credential
        |> Map.delete("token")
        |> Map.put("renewedAt", now)
        |> sign(auth_key, require_cols, opts[:verify] || 0)

      ["verify", auth_key | _] ->
        case FlightAuth.verify(auth_key, opts[:expire], data["token"]) do
          {:ok,    credential} -> credential |> puts_result
          {:error, message}    -> message    |> puts_result(101)
        end

      _ -> "unknown command: #{arguments}" |> puts_error
    end
  end

  defp sign(data,auth_key,require_cols,verify) do
    case data["signedAt"] |> DateTime.from_iso8601 do
      {:ok, signed_at, _offset} ->
        if DateTime.utc_now |> DateTime.diff(signed_at) < verify do
          sign(data,auth_key,require_cols)
        else
          "signed_at expired: #{signed_at |> inspect}"
          |> puts_result(101)
        end
      {:error, message} ->
        "failed parse signed_at: #{message}"
        |> puts_result(101)
    end
  end
  defp sign(data,auth_key,require_cols) do
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

  defp parse_data(key) do
    System.get_env(key)
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
