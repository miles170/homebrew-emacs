class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftpmirror.gnu.org/gnu/emacs/emacs-31.1.tar.xz"
  mirror "https://ftp.gnu.org/gnu/emacs/emacs-31.1.tar.xz"
  sha256 "1da5790d9580c81932b5bf700633114468da7b3412d69faa767daebf974f4586"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://mirrors.kernel.org/gnu/emacs/"
    regex(/href=.*?emacs-v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "pkgconf" => :build
  depends_on "texinfo" => :build

  depends_on "gcc"
  depends_on "gmp"
  depends_on "gnutls"
  depends_on "libgccjit"
  depends_on "libxml2"
  depends_on :linux
  depends_on "ncurses"
  depends_on "sqlite"
  depends_on "tree-sitter"
  depends_on "zlib-ng-compat"

  def install
    args = %W[
      --disable-silent-rules
      --disable-xattr
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
      --without-all
      --without-x
      --with-file-notification=inotify
      --with-gnutls
      --with-modules
      --with-native-compilation=aot
      --with-sqlite3
      --with-systemduserunitdir=no
      --with-threads
      --with-tree-sitter
      --with-xml2
      --with-zlib
    ]

    gcc_major = Formula["gcc"].version.major
    ENV["CC"] = formula_opt_bin("gcc")/"gcc-#{gcc_major}"
    ENV.append "CPPFLAGS", "-I#{formula_opt_include("libgccjit")}"
    ENV.append "LDFLAGS", "-L#{formula_opt_lib("gcc")/"gcc/current"}"
    ENV.append "LDFLAGS", "-L#{formula_opt_lib("libgccjit")/"gcc/current"}"

    File.write "lisp/site-load.el", <<~LISP
      (setq exec-path (delete nil
        (mapcar
          (lambda (path)
            (unless (string-match-p "Homebrew/shims" path) path))
          exec-path)))
    LISP

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  service do
    run [opt_bin/"emacs", "--fg-daemon"]
    keep_alive true
  end

  test do
    emacs = "#{bin}/emacs --quick --batch"
    assert_equal "4", shell_output("#{emacs} --eval=\"(print (+ 2 2))\"").strip

    %w[
      gnutls-available-p
      libxml-available-p
      sqlite-available-p
      treesit-available-p
      zlib-available-p
    ].each do |feature|
      assert_equal "t", shell_output("#{emacs} --eval=\"(print (and (#{feature}) t))\"").strip
    end

    configuration = shell_output("#{emacs} --eval=\"(princ system-configuration-features)\"")
    %w[INOTIFY MODULES NOTIFY THREADS].each do |feature|
      assert_match feature, configuration
    end

    assert_equal "t", shell_output("#{emacs} --eval=\"(print (native-comp-available-p))\"").strip
  end
end
