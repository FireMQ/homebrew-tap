class Firemq < Formula
  desc "Lean, fast, RabbitMQ-compatible message broker"
  homepage "https://github.com/FireMQ/firemq"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-aarch64-apple-darwin.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-x86_64-apple-darwin.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-aarch64-unknown-linux-musl.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-x86_64-unknown-linux-musl.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
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
