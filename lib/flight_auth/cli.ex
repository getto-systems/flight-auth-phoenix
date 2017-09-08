defmodule FlightAuth.CLI do
  def main(arguments) do
    {opts, args, _} = OptionParser.parse(arguments, strict: [
      password: :string,
      loginID: :string,
      role: :string,
      expire: :integer,
    ])

    data = parse_data("FLIGHT_DATA")
    credential = parse_data("FLIGHT_CREDENTIAL")

    password_col = opts[:password] || "password"
    loginID_col = opts[:loginID] || "loginID"
    role_col = opts[:role] || "role"

    require_cols = [loginID_col, role_col]

    case args do
      ["password-hash", kind, salt | _] ->
        data |> update_in(["data"], fn data ->
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
        end)
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
        data
        |> Map.delete(password_col)
        |> sign(auth_key, require_cols)

      ["renew", auth_key | _] ->
        credential
        |> Map.delete("token")
        |> sign(auth_key, require_cols)

      ["verify", auth_key | _] ->
        case FlightAuth.verify(auth_key, opts[:expire], data["token"]) do
          {:ok,    credential} -> credential |> puts_result
          {:error, message}    -> message    |> puts_result(101)
        end

      _ -> "unknown command: #{arguments}" |> puts_error
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
