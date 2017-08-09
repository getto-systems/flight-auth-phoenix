defmodule FlightAuth do
  @moduledoc """
  authorization module for getto/flight
  """

  @doc """
  create token from salt and structure
  """
  def sign(auth_key, data) do
    Phoenix.Token.sign(FlightAuthWeb.Endpoint, auth_key, data)
    |> Base.encode64
  end

  @doc """
  verify token by salt and max_age second
  """
  def verify(auth_key, max_age, token) do
    case token |> Base.decode64 do
      {:ok, phx_token} -> Phoenix.Token.verify(FlightAuthWeb.Endpoint, auth_key, phx_token, max_age: max_age)
      _ -> {:error, :invalid_base64}
    end
  end

  @doc """
  hash password

  ## Examples

      iex> FlightAuth.password_hash("password", "salt")
      "j0/iFH52Dp/ADEcVnDyorUMcuSjSQDV5/ks3FSDV8oI="

  """
  def password_hash(password, salt) do
    secret = Application.get_env(:flight_auth, FlightAuthWeb.Endpoint)[:secret_key_base]
    :crypto.hash(:sha256, "#{secret}#{password}#{salt}") |> Base.encode64
  end
end
