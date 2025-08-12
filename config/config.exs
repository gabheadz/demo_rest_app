import Config

config :demo_rest_app, DemoRestApp.Router,
       port: String.to_integer(System.get_env("PORT") || "4000")

config :libcluster,
       topologies: [
         erlang_nodes_in_k8s: [
           strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
           config: [
             polling_interval: 5_000,
             service: "demo-rest-app-headless",
             application_name: "demo_rest_app",
             namespace: "demo",
           ]
         ]
       ]

config :demo_rest_app, DemoRestApp.Cache,
       primary: [
         # When using :shards as backend
         #backend: :shards,
         # GC interval for pushing new generation: 12 hrs
         gc_interval: :timer.hours(12),
         # Max 1 million entries in cache
         max_size: 1_000_000,
         # Max 2 GB of memory
         allocated_memory: 2_000_000_000,
         # GC min timeout: 10 sec
         gc_cleanup_min_timeout: :timer.seconds(10),
         # GC max timeout: 10 min
         gc_cleanup_max_timeout: :timer.minutes(10)
       ]