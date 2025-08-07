# DemoRestApp

A demo application for demonstrating RESTful APIs in Elixir.

## How does it work?

Esta aplicacion expone dos endpoints:

### Endpoint HELLO

`GET /hello/:name`

Devuelve un saludo para el `:name` dado como parametro. Ese `:name` es buscado en una cache
y si no existe, se crea un nuevo registro en el cache con el `:name` como key.

Ejemplo: 
```
$ curl -i localhost:4000/hello/Gabo

HTTP/1.1 200 OK

Hello, Gabo! This is your first visit.%     
```

Como el usuario no existe en el cache, se crea un registro en el cache con el key "Gabo".

Si se vuelve a llamar al mismo endpoint con el mismo nombre, por ejemplo:

```
$ curl -i localhost:4000/hello/Gabo

HTTP/1.1 200 OK

Hello again, Gabo!%     
```

Como el usuario ya existe en el cache, se devuelve un saludo diferente.

### Endpoint BYE


`DELETE /bye/:name`

Se despide de un usuario identificado por `:name` y elimina su registro del cache. 

```
$ curl -i --request DELETE localhost:4000/bye/Gabo

HTTP/1.1 200 OK

bye Gabo!%   
```

Si el usuario no existe, devuelve mensaje indicando que no conoce a ese usuario.

```
$ curl -i --request DELETE localhost:4000/bye/Gabo

HTTP/1.1 200 OK

Gabo? who are you?%   
```

La operacion de borrado se replica a todos los nodos del cluster, de modo que si se borra un usuario en un nodo, 
se invoca la operacion de borrados en todos los nodos.

## Propagacion del borrado 

### Uso de libcluster

Se usa libcluster para permitir que varios nodos de la aplicacion se comuniquen entre si.

```elixir
  defp deps do
    [
      {:libcluster, "~> 3.3"}
    ]
  end
```

se debe configurar el cluster en el archivo `config/config.exs`:

```elixir
config :libcluster,
       topologies: [
         erlang_nodes_in_k8s: [
           strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
           config: [
             polling_interval: 5_000,
             service: "demo-rest-app-headless", # nombre del servicio headless de k8s (ver demo_rest_app.yaml)
             application_name: "demo_rest_app", # nombre de la aplicacion, como se define en el mix.exs
             namespace: "demo", # namespace de k8s donde se ejecuta la aplicacion
           ]
         ]
       ]
```

Se carga la configuracion del cluster en el archivo `lib/demo_rest_app/application.ex`:

```elixir
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) # se obtiene la configuracion del cluster

    children = [
      {Cluster.Supervisor, [topologies, [name: DemoRestApp.ClusterSupervisor]]}, # se crea el supervisor del cluster
      # otros hijos del supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoRestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

### Broadcast del borrado

Para propagar el borrado a todos los nodos del cluster, se usa el metodo `:rpc.call/4` de erlang. El cual es una operacion
sincrona.

```elixir
  def delete_key_all_nodes(key) do
    # Local delete
    Cachex.del(:my_cache, key)

    # Remote deletes
    Node.list()
    |> Enum.each(fn node ->
      :rpc.call(node, Cachex, :del, [:my_cache, key])
    end)
  end
```

Alternativamente se puede usar el metodo `:rpc.cast/4` para hacer el borrado en todos los nodos de manera asíncrona:

### Validacion del borrado

Despues de invocar el endpoint `/hello/Gabo`. Este elemento se agrega al cache del nodo que recibe la peticion.

Si se tienen varios nodos, y se sigue invocando el endpoint `/hello/Gabo` en otros nodos, se ira almacenando en el
cache de cada nodo. 

Para ver los keys en cada nodo:

```
$ kubectl exec -it demo-rest-app-<nodo1> -n demo -- /bin/sh

/app> ./bin/demo_rest_app remote

Erlang/OTP 26 [erts-14.2.5.10] [source] [64-bit] [smp:6:6] [ds:6:6:10] [async-threads:1] [jit]

Interactive Elixir (1.16.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(demo_rest_app@10.42.0.30)1> Cachex.keys(:my_cache)
{:ok, ["Gabo"]}
```

Despues de invocar el endpoint `/bye/Gabo`, se elimina el key "Gabo" del cache del nodo que reciba la peticion
y luego se propaga a los otros nodos.

Si se verifican los nodos uno a uno se vera que el key "Gabo" ya no existe en el cache.

```
$ kubectl exec -it demo-rest-app-<nodo1, 2, 3, n> -n demo -- /bin/sh

/app> ./bin/demo_rest_app remote

Erlang/OTP 26 [erts-14.2.5.10] [source] [64-bit] [smp:6:6] [ds:6:6:10] [async-threads:1] [jit]

Interactive Elixir (1.16.3) - press Ctrl+C to exit (type h() ENTER for help)

iex(demo_rest_app@10.42.0.30)1> Cachex.keys(:my_cache)
{:ok, []}
```
