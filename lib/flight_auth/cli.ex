defmodule FlightAuth.CLI do
  def main(arguments) do
    {opts, args, _} = OptionParser.parse(arguments, strict: [
      password: :string,
      role: :string,
      expire: :integer,
    ])

    data = System.get_env("FLIGHT_DATA") |> Poison.decode!

    password_col = opts[:password] || "password"
    role_col = opts[:role] || "role"

    case args do
      ["password-hash", kind, salt | _] ->
        data |> update_in(["data"], fn operates ->
          operates |> Enum.reduce([], fn operate, acc ->
            operate = case operate["kind"] do
              ^kind -> operate |> update_in(["properties",password_col], &(&1 |> FlightAuth.password_hash(salt)))
              _     -> operate
            end
            [operate | acc]
          end) |> Enum.reverse
        end)
        |> puts_result

      ["format-for-auth", salt | _] ->
        %{
          "key" => data["key"],
          "conditions" => %{
            password_col => data[password_col] |> FlightAuth.password_hash(salt),
          },
          "columns" => [role_col],
        }
        |> puts_result

      ["sign", auth_key | _] ->
        case data[role_col] do
          nil -> "no role in data: #{data}" |> puts_error
          role ->
            data
            |> Map.put("token", FlightAuth.sign(auth_key, role))
            |> puts_result
        end

      ["verify", auth_key | _] ->
        case FlightAuth.verify(auth_key, opts[:expire], data["token"]) do
          {:ok,    role}    -> role    |> puts_result
          {:error, message} -> message |> puts_error
        end

      _ -> "unknown command: #{arguments}" |> puts_error
    end
  end

  defp puts_result(data) do
    IO.puts(data |> Poison.encode!)
  end
  defp puts_error(message) do
    IO.puts(:stderr, "#{__MODULE__}: [ERROR] #{message}")
  end
end
