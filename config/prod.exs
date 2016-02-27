use Mix.Config

config :wameku_server_scratch,
  home_directory: (System.get_env("WAMEKU_HOME") || "/opt/wameku"),
  amqp: %{
          username: System.get_env("WAMEKU_AMQP_USERNAME"),
          password: System.get_env("WAMEKU_AMQP_PASSWORD"),
          queue_name: System.get_env("WAMEKU_AMQP_QUEUE_NAME"),
          host: System.get_env("WAMEKU_AMQP_HOST"),
          virtual_host: System.get_env("WAMEKU_AMQP_VIRTUAL_HOST"),
          exchange_name: System.get_env("WAMEKU_AMQP_EXCHANGE_NAME")
         }
