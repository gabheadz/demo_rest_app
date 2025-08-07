defmodule DemoRestApp.CacheBroadcaster do
  @moduledoc false

  @spec delete_key_all_nodes(String.t()) :: :ok
  @doc """
  Deletes a key from the local cache and broadcasts the deletion to all nodes in the cluster.
  This function uses Cachex for local cache management and :rpc for remote procedure calls to other nodes.
  """
  def delete_key_all_nodes(key) do
    # Local delete
    Cachex.del(:my_cache, key)

    # Remote deletes
    Node.list()
    |> Enum.each(fn node ->
      :rpc.call(node, Cachex, :del, [:my_cache, key])
    end)
  end

end
