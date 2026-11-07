# FireMQ Homebrew tap

Installs [FireMQ](https://github.com/FireMQ/firemq), a lean, RabbitMQ-compatible message broker, on macOS and Linux.

```bash
brew install firemq/tap/firemq
firemq
```

`firemq` starts a broker with RabbitMQ's ports: AMQP on 5672, the FireMQ protocol on 5673, and the management UI on <http://localhost:15672>. Log in as `guest` with password `guest`.

To run it in the background and start it at login:

```bash
brew services start firemq
```

The service keeps its data in `$(brew --prefix)/var/firemq` and logs to `$(brew --prefix)/var/log/firemq.log`.

> **Status:** the formula installs FireMQ release binaries. It works once FireMQ v0.1.0 is released; until then, use `cargo install --git https://github.com/FireMQ/firemq firemq`.

## How the formula is kept current

The [Update formula](.github/workflows/update.yml) workflow runs `scripts/update.sh` daily and on demand. The script reads the checksums published with the latest FireMQ release and rewrites `Formula/firemq.rb`. The [Check](.github/workflows/check.yml) workflow runs `brew style` and installs the formula from an archive built from source, then runs its test.

To update by hand:

```bash
scripts/update.sh v0.1.0
```

## License

Apache-2.0
