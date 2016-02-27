# WamekuServerScratch

## This is not usable code.

This code expects a config file to exist under `/tmp/checks/config/notify/notifiers.json`

The format of file should be

```json
{
   "stdout": {
    "path": "/tmp/checks/stdout_notifier.sh",
    "arguments": []
  },
  "foobar": {
    "path": "/tmp/checks/foobar_notifier.sh",
    "arguments": []
  }

}
```

The code also expects a `RabbitMQ` server running locally with a `guest/guest` access.

The handler should expect a json hash as an argument.
For example, this is how wameku server will call the handler.

```elixir
Porcelain.exec("/opt/wameku/handlers/mailer.sh", [Poison.encode!(%{name: "foo-check-disk", output: "OK", exit_code: 1})])
```

## TODO

* Need a way to override notifications for some period of time.

* Need a way to delete client

* Nice to have metrics built in to server
