class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftp.gnu.org/gnu/emacs/emacs-29.1.tar.xz"
  mirror "https://ftpmirror.gnu.org/emacs/emacs-29.1.tar.xz"
  sha256 "d2f881a5cc231e2f5a03e86f4584b0438f83edd7598a09d24a21bd8d003e2e01"
  license "GPL-3.0-or-later"
  revision 1

  head do
    url "https://github.com/emacs-mirror/emacs.git", branch: "master"
  end

  option "with-native-comp", "Build with native compilation"

  depends_on "autoconf" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "gnutls"
  depends_on "jansson"
  depends_on "sqlite"
  depends_on "tree-sitter"

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  if build.with? "native-comp"
    depends_on "libgccjit" => :recommended
    depends_on "gcc" => :build
  end

  on_linux do
    depends_on "jpeg-turbo"
  end

  def install
    # Mojave uses the Catalina SDK which causes issues like
    # https://github.com/Homebrew/homebrew-core/issues/46393
    # https://github.com/Homebrew/homebrew-core/pull/70421
    ENV["ac_cv_func_aligned_alloc"] = "no" if MacOS.version == :mojave

    args = %W[
      --disable-silent-rules
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
      --with-gnutls
      --without-x
      --with-xml2
      --without-dbus
      --with-modules
      --without-ns
      --without-imagemagick
      --without-selinux
      --with-tree-sitter
      --with-json
    ]

    if build.with? "native-comp"
      gcc_major_ver = Formula["gcc"].any_installed_version.major
      gcc = Formula["gcc"].opt_bin/"gcc-#{gcc_major_ver}"
      gcc_libs = "#{HOMEBREW_PREFIX}/lib/gcc/#{gcc_major_ver}"

      ENV["CC"] = gcc
      ENV.append "CFLAGS", "-I#{Formula["gcc"].include}"
      ENV.append "LDFLAGS", "-L#{gcc_libs}"

      args << "--with-native-compilation"
      ENV.append "CFLAGS", "-I#{Formula["libgccjit"].include}"
    end

    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
    system "./autogen.sh"

    File.write "lisp/site-load.el", <<~EOS
      (setq exec-path (delete nil
        (mapcar
          (lambda (elt)
            (unless (string-match-p "Homebrew/shims" elt) elt))
          exec-path)))
    EOS

    system "./configure", *args
    system "make"
    system "make", "install"

    # Follow MacPorts and don't install ctags from Emacs. This allows Vim
    # and Emacs and ctags to play together without violence.
    (bin/"ctags").unlink
    (man1/"ctags.1.gz").unlink
  end

  service do
    run [opt_bin/"emacs", "--fg-daemon"]
    keep_alive true
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
