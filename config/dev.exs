use Mix.Config

config :wameku_server_scratch,
  home_directory: "/opt/wameku",
  amqp: %{username: "guest", password: "guest", queue_name: "clients", host: "127.0.0.1", virtual_host: "/", exchange_name: "clients_exchange"}
