defmodule FlightAuthWeb.Router do
  use FlightAuthWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", FlightAuthWeb do
    pipe_through :api
  end
end
