class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftp.gnu.org/gnu/emacs/emacs-28.2.tar.xz"
  mirror "https://ftpmirror.gnu.org/emacs/emacs-28.2.tar.xz"
  sha256 "ee21182233ef3232dc97b486af2d86e14042dbb65bbc535df562c3a858232488"
  license "GPL-3.0-or-later"

  head do
    url "https://github.com/emacs-mirror/emacs.git", branch: "master"
  end

  option "with-json", "Build with fast JSON"
  option "with-native-comp", "Build with native compilation"

  depends_on "autoconf" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "gnutls"
  depends_on "jansson"
  depends_on "jpeg"

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  if build.with? "json"
    depends_on "jansson"
    depends_on "gcc" => :build
  end

  if build.with? "native-comp"
    depends_on "libgccjit"
    depends_on "gcc" => :build
  end

  def install
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
    ]

    if build.with?("native-comp") || build.with?("json")
      args << "--with-native-compilation" if build.with? "native-comp"
      args << "--with-json" if build.with? "json"

      gcc_major_ver = Formula["gcc"].any_installed_version.major
      gcc = Formula["gcc"].opt_bin/"gcc-#{gcc_major_ver}"
      gcc_libs = "#{HOMEBREW_PREFIX}/lib/gcc/#{gcc_major_ver}"

      ENV["CC"] = gcc
      ENV.append "CFLAGS", "-I#{Formula["gcc"].include}"
      ENV.append "CFLAGS", "-I#{Formula["libgccjit"].include}"
      ENV.append "LDFLAGS", "-L#{gcc_libs}"
    end

    if build.head? || build.with?("native-comp") || build.with?("json")
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
      system "./autogen.sh"
    end

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
