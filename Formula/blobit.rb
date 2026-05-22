class Blobit < Formula
  desc "CLI for Blobit projects, assets, jobs, scenes, and publishing"
  homepage "https://www.blobit.ai"
  version "0.1.2"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/3dMVP/CLI/releases/download/v0.1.2/blobit-v0.1.2-aarch64-apple-darwin.zip"
      sha256 "b07388839fdf879a659554d8e07e56ef792f13b679afb42d0e3cf4c897aae291"
    else
      url "https://github.com/3dMVP/CLI/releases/download/v0.1.2/blobit-v0.1.2-x86_64-apple-darwin.zip"
      sha256 "b1d9b5b60694d3d0a234eb003dafe0b9cf6dbe00e9752d02a69822e0f1119468"
    end
  end

  on_linux do
    depends_on "dbus"

    url "https://github.com/3dMVP/CLI/releases/download/v0.1.2/blobit-v0.1.2-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "49e24316871686640312c452edd5a2741e1629e6ace6b8973fc31d02646fd844"
  end

  def install
    bin.install "blobit"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/blobit --help")
  end
end
