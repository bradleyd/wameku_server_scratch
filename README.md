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