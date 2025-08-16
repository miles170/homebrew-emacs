class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftpmirror.gnu.org/gnu/emacs/emacs-30.2.tar.xz"
  mirror "https://ftp.gnu.org/gnu/emacs/emacs-30.2.tar.xz"
  sha256 "b3f36f18a6dd2715713370166257de2fae01f9d38cfe878ced9b1e6ded5befd9"
  license "GPL-3.0-or-later"

  option "with-native-comp", "Build with native compilation"

  depends_on "autoconf" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "gnutls"
  depends_on "jpeg-turbo"
  depends_on "libxml2"
  depends_on :linux
  depends_on "ncurses"
  depends_on "sqlite"
  depends_on "tree-sitter"

  if build.with? "native-comp"
    depends_on "libgccjit"
    depends_on "gcc"
  end

  def install
    args = %W[
      --disable-acl
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
      --without-cairo
      --without-harfbuzz
      --without-libotf
      --without-m17n-flt
      --without-toolkit-scroll-bars
      --without-xaw3d
      --without-gif
      --without-tiff
      --without-png
      --without-rsvg
      --without-lcms2
      --without-xpm
      --without-gpm
    ]

    if build.with? "native-comp"
      gcc_major_ver = Formula["gcc"].any_installed_version.major
      gcc = Formula["gcc"].opt_bin/"gcc-#{gcc_major_ver}"
      gcc_libs = "#{HOMEBREW_PREFIX}/lib/gcc/#{gcc_major_ver}"

      ENV["CC"] = gcc
      ENV.append "CFLAGS", "-I#{Formula["gcc"].include}"
      ENV.append "LDFLAGS", "-L#{gcc_libs}"

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
    assert_equal "t", shell_output("#{bin}/emacs --batch --eval=\"(print (json-available-p))\"").strip
    assert_equal "t", shell_output("#{bin}/emacs --batch --eval=\"(print (sqlite-available-p))\"").strip

    if build.with? "native-comp"
      assert_equal "t", shell_output("#{bin}/emacs --batch --eval=\"(print (native-comp-available-p))\"").strip
    end
  end
end
