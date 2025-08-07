defmodule DemoRestApp.Router do
  @moduledoc false
  use Plug.Router

  alias DemoRestApp.CacheBroadcaster

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome to the Demo REST App!")
  end

  @doc """
  Handles a GET request to greet a user by name.
  If the user has visited before, it responds with a different message.
  If the user is new, it stores their name in the cache.
  """
  get "/hello/:name" do
    # check if the name provided in the URL is already in the cache
    case Cachex.exists?(:my_cache, "#{name}") do
      {:ok, true} ->
        # User has visited before
        send_resp(conn, 200, "Hello again, #{name}!")
      { :ok, false } ->
        # User is new, store their name in the cache
        Cachex.put(:my_cache, "#{name}", true)
        send_resp(conn, 200, "Hello, #{name}! This is your first visit.")
    end
  end

  @doc """
  Handles a DELETE request to say goodbye to a user by name.
  If the user exists in the cache, it deletes their name and responds with a goodbye message.
  If the user does not exist, it responds with a message indicating that the user is unknown.
  """
  delete "/bye/:name" do
    # check if the name provided in the URL exists in the cache
    case Cachex.exists?(:my_cache, "#{name}") do
      {:ok, true} ->
        # User exists, delete their name from the cache, broadcast the deletion
        CacheBroadcaster.delete_key_all_nodes("#{name}")
        send_resp(conn, 200, "bye #{name}!")
      _ ->
        send_resp(conn, 200, "#{name}? I dont know you!")
    end
  end

  match _ do
    send_resp(conn, 404, "Oops! Not found.")
  end

end
