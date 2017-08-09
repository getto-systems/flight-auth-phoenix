defmodule FlightAuth.CLI do
  def main(args) do
    {opts, args, _} = OptionParser.parse(args, strict: [file: :string, expire: :integer, token: :string])
    case args do
      ["sign", auth_key | _] ->
        case opts[:file] do
          nil -> puts_error("data file no detected")
          file ->
            case File.read(file) do
              {:error, message} -> puts_error(message)
              {:ok, data} ->
                case Poison.decode(data) do
                  {:error, message} -> puts_error(inspect(message))
                  {:error, message, data} -> puts_error(inspect({message, data}))
                  {:ok, json} ->
                    case json["role"] do
                      nil -> puts_error("no role in json data")
                      role ->
                        json = json
                               |> Map.put("token", FlightAuth.sign(auth_key, role))
                               |> Poison.encode!
                        case File.write(file, json) do
                          :ok -> nil
                          {:error, message} -> puts_error(message)
                        end
                    end
                end
            end
        end

      ["verify", auth_key | _] ->
        case FlightAuth.verify(auth_key, opts[:expire], opts[:token]) do
          {:ok, data} -> IO.puts(data)
          {:error, message} -> puts_error(message)
        end

      _ -> puts_error("unknown command")
    end
  end

  defp puts_error(message) do
    IO.puts(:stderr, "flight_auth: [ERROR] #{message}")
  end
end
