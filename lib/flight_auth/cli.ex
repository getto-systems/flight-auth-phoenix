defmodule FlightAuth.CLI do
  def main(args) do
    {opts, args, _} = OptionParser.parse(args, strict: [expire: :integer])
    case args do
      ["sign", auth_key, data | _] ->
        # TODO データは data.json から取得
        # json を解析して role を取り出して sign する
        # 結果は data.json に書き込む {"token": <token>}
        IO.puts(FlightAuth.sign(auth_key, data))
      ["verify", auth_key, data | _] ->
        case FlightAuth.verify(auth_key, opts[:expire], data) do
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
