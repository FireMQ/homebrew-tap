#!/usr/bin/env bash
# Writes Formula/firemq.rb for a FireMQ release, reading checksums from the release assets.
#
#   scripts/update.sh            # latest release
#   scripts/update.sh v0.1.0     # a given tag
set -euo pipefail
cd "$(dirname "$0")/.."
# PLACEHOLDER=1 writes zero checksums, for before the first release.
tag=${1:-$(curl -fsSL https://api.github.com/repos/FireMQ/firemq/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')}
version=${tag#v}
base="https://github.com/FireMQ/firemq/releases/download/$tag"
sha() { curl -fsSL "$base/firemq-$1.tar.gz.sha256" | awk '{print $1}'; }
if [ -n "${PLACEHOLDER:-}" ]; then sha() { printf '%064d' 0; }; fi

mac_arm=$(sha aarch64-apple-darwin)
mac_intel=$(sha x86_64-apple-darwin)
linux_arm=$(sha aarch64-unknown-linux-musl)
linux_intel=$(sha x86_64-unknown-linux-musl)

cat > Formula/firemq.rb <<RUBY
class Firemq < Formula
  desc "Lean, fast, RabbitMQ-compatible message broker"
  homepage "https://github.com/FireMQ/firemq"
  version "$version"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "$base/firemq-aarch64-apple-darwin.tar.gz"
      sha256 "$mac_arm"
    end
    on_intel do
      url "$base/firemq-x86_64-apple-darwin.tar.gz"
      sha256 "$mac_intel"
    end
  end

  on_linux do
    on_arm do
      url "$base/firemq-aarch64-unknown-linux-musl.tar.gz"
      sha256 "$linux_arm"
    end
    on_intel do
      url "$base/firemq-x86_64-unknown-linux-musl.tar.gz"
      sha256 "$linux_intel"
    end
  end

  def install
    bin.install "firemq"
    generate_completions_from_executable(bin/"firemq", "completions")
  end

  service do
    run [opt_bin/"firemq", "serve", "--data-dir", var/"firemq"]
    keep_alive true
    working_dir var
    log_path var/"log/firemq.log"
    error_log_path var/"log/firemq.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/firemq --version")
    port = free_port
    http = free_port
    pid = spawn bin/"firemq", "--ephemeral", "--amqp", "127.0.0.1:#{free_port}",
                "--fire", "127.0.0.1:#{port}", "--http", "127.0.0.1:#{http}",
                "--amqps", "off", "--fires", "off"
    begin
      sleep 2
      system bin/"firemq", "ctl", "--url", "http://127.0.0.1:#{http}", "declare-queue", "brew"
      system bin/"firemq", "pub", "--url", "fire://127.0.0.1:#{port}", "--queue", "brew", "hello"
      assert_match "hello", shell_output("#{bin}/firemq sub --url fire://127.0.0.1:#{port} brew --count 1")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
RUBY
echo "Formula/firemq.rb now points at $tag"
