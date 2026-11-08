class Firemq < Formula
  desc "Lean, fast, RabbitMQ-compatible message broker"
  homepage "https://github.com/FireMQ/firemq"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-aarch64-apple-darwin.tar.gz"
      sha256 "34799d93729d0c868e42b8e0ffb0a3aa91ab7fbe5774f8dff0067a8009f3d93e"
    end
    on_intel do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-x86_64-apple-darwin.tar.gz"
      sha256 "d07803281c6397855b12cb698dda997302c5b46065c9b9eee7137bfd92af08c8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-aarch64-unknown-linux-musl.tar.gz"
      sha256 "ef148d0a7de2b526831c35f7cd9356dd16591389fe946fb0eacf86933892cb58"
    end
    on_intel do
      url "https://github.com/FireMQ/firemq/releases/download/v0.1.0/firemq-x86_64-unknown-linux-musl.tar.gz"
      sha256 "ac65ab8cfd8e2ddbb8fea76bd057f6342c2f40199641065e84d1d4a645acc501"
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
