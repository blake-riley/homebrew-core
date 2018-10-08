class Squashfs < Formula
  desc "Compressed read-only file system for Linux"
  homepage "https://squashfs.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/squashfs/squashfs/squashfs4.3/squashfs4.3.tar.gz"
  sha256 "0d605512437b1eb800b4736791559295ee5f60177e102e4d4ccd0ee241a5f3f6"
  revision 2
  head "https://github.com/plougher/squashfs-tools", :using => :git, :commit => "6e242dc95485ada8d1d0b3dd9346c5243d4a517f"

  bottle do
    cellar :any
    sha256 "c48d6bf745747564c7b8736c1f703165d0787415d54c09680e272e2d68fdd572" => :mojave
    sha256 "59fe238379463c52b0e219192139180be496fcc20adc734a84699f34191461c3" => :high_sierra
    sha256 "2e015389c160a1094f0995e3d5b11f54b0549cbab7a506cbb2706608213735a6" => :sierra
  end

  option "with-zstd", "Build with zstd support (currently only supported with --HEAD)"
  depends_on "lzo"
  depends_on "xz"
  depends_on "lz4" => :optional
  depends_on "zstd" => :optional # Not in 4.3 release, only in HEAD

  # Patch necessary to emulate the sigtimedwait process otherwise we get build failures
  # Also clang fixes, extra endianness knowledge and a bundle of other macOS fixes.
  # Originally from https://github.com/plougher/squashfs-tools/pull/3
  if build.head? # Updated patch for the HEAD commit (won't match otherwise)
    patch do
      url "https://gist.githubusercontent.com/blake-riley/b1d62c0c6eabe8209a77fbd4456124e7/raw/4ddeb316c1fd8808bdcc5cd6ad833d8db58ca07e/squashfs-osx-bundle.diff"
      sha256 "61d1e8df8a79e542fcb470d75227e3661bd58a4816ea9d06b608b07292b13265"
    end
  else
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/05ae0eb1/squashfs/squashfs-osx-bundle.diff"
      sha256 "276763d01ec675793ddb0ae293fbe82cbf96235ade0258d767b6a225a84bc75f"
    end
  end

  def install
    args = %W[
      EXTRA_CFLAGS=-std=gnu89
      LZ4_SUPPORT=1
      LZMA_XZ_SUPPORT=1
      LZO_DIR=#{Formula["lzo"].opt_prefix}
      LZO_SUPPORT=1
      XATTR_SUPPORT=0
      XZ_DIR=#{Formula["xz"].opt_prefix}
      XZ_SUPPORT=1
    ]
    args << "LZ4_SUPPORT=1" if build.with? "lz4"
    if build.with? "zstd"
      if build.head?
        args << "ZSTD_SUPPORT=1"
        args << "ZSTD_DIR=#{Formula["zstd"].opt_prefix}"
      else
        odie "Option --with-zstd is currently only supported with --HEAD."
      end
    end

    cd "squashfs-tools" do
      system "make", *args
      bin.install %w[mksquashfs unsquashfs]
    end
    if build.head?
      doc.install %w[ACKNOWLEDGEMENTS INSTALL RELEASE-README RELEASE-READMEs]
    else
      doc.install %w[ACKNOWLEDGEMENTS INSTALL OLD-READMEs PERFORMANCE.README README-4.3]
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/unsquashfs -v", 1)
  end
end
