class Scrim < Formula
  desc "Minimal headless browser for AI agents: one binary, no layout, no paint"
  homepage "https://github.com/strelov1/scrim"
  # Prebuilt binary from the project's own CI (.github/workflows/build.yml), which builds and
  # smoke-tests it on a macOS arm64 runner and attaches the tarball to the tagged release.
  # The version is scanned from this URL.
  url "https://github.com/strelov1/scrim/releases/download/v0.1.0/scrim-0.1.0-macos-arm64.tar.gz"
  sha256 "6bdc88925f43e51ca5884db1e44d5d058357515f249332c42321810a3764a879"
  license "MIT"

  # The bundled V8 archive is built with chained fixups, so the binary needs macOS 14 or newer.
  depends_on arch: :arm64
  depends_on macos: :sonoma

  def install
    bin.install "scrim"
  end

  test do
    assert_match "scrim #{version}", shell_output("#{bin}/scrim --version")

    # Read a page end to end: the binary must run JavaScript and keep hidden text out.
    (testpath/"index.html").write <<~HTML
      <!doctype html><p>hello scrim</p>
      <p style="display:none">hidden</p>
      <script>document.body.insertAdjacentHTML("beforeend","<p>from javascript</p>")</script>
    HTML
    port = free_port
    pid = spawn "python3", "-m", "http.server", port.to_s, "--directory", testpath
    begin
      sleep 2
      out = shell_output("#{bin}/scrim fetch http://127.0.0.1:#{port}/")
      assert_match "hello scrim", out
      assert_match "from javascript", out
      refute_match "hidden", out
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
