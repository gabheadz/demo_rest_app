defmodule DemoRestApp.Cache do
  @moduledoc false
  use Nebulex.Cache,
      otp_app: :demo_rest_app,
      adapter: Nebulex.Adapters.Partitioned # tambien puede ser Replicated
end
