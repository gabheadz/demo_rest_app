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