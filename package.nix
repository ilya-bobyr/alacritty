{ stdenv
, lib
, rustPlatform
, nixosTests

, cmake
, installShellFiles
, makeWrapper
, ncurses
, pkg-config
, python3
, scdoc
, gzip

, expat
, fontconfig
, freetype
, libGL
, xorg
, libxkbcommon
, wayland
, xdg-utils

# TODO AppKit is not available on Linux it seems.  So `callPackage` fails with
# an error like this:
#
# lib.customisation.callPackageWith:
#   Function called without required argument "AppKit" at
#   /nix/store/3xw7hgp6gg781b25yv5fa5rn67spm0sc-source/package.nix:23
#
# What is the right solution here?
# Can I require this arguments only on Darwin somehow?
#
#   # Darwin Frameworks
# , AppKit
# , CoreGraphics
# , CoreServices
# , CoreText
# , Foundation
# , libiconv
# , OpenGL
}:
let
  rpathLibs = [
    expat
    fontconfig
    freetype
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXxf86vm
    xorg.libxcb
  ] ++ lib.optionals stdenv.isLinux [
    libxkbcommon
    wayland
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "my-alacritty";
  version = "0.15.0-dev";

  src = ./.;

  # This is a hash that identifies the whole dependency tree that `cargo`
  # generates for this binary.  Essentially, a hash of `Cargo.lock`, I think,
  # except that the lock file seems to be regenerated on every build, rather
  # than being part of the source tree.
  #
  # TODO It is pretty annoying that I need to update this every time.  I wonder
  # if I really need it.  Is there a way to include `Cargo.lock` and fix the
  # hash?
  cargoHash = lib.fakeHash;

  nativeBuildInputs = [
    cmake
    installShellFiles
    makeWrapper
    ncurses
    pkg-config
    python3
    scdoc
    gzip
  ];

  buildInputs = rpathLibs;
  #   ++ lib.optionals stdenv.isDarwin [
  #   AppKit
  #   CoreGraphics
  #   CoreServices
  #   CoreText
  #   Foundation
  #   libiconv
  #   OpenGL
  # ];

  outputs = [ "out" "terminfo" ];

  postPatch = lib.optionalString (!xdg-utils.meta.broken) ''
    substituteInPlace alacritty/src/config/ui_config.rs \
      --replace-fail xdg-open ${xdg-utils}/bin/xdg-open
  '';

  checkFlags = [ "--skip=term::test::mock_term" ]; # broken on aarch64

  postInstall = (
    if stdenv.isDarwin then ''
      mkdir $out/Applications
      cp -r extra/osx/Alacritty.app $out/Applications
      ln -s $out/bin $out/Applications/Alacritty.app/Contents/MacOS
    '' else ''
      install -D extra/linux/Alacritty.desktop -t $out/share/applications/
      install -D extra/linux/org.alacritty.Alacritty.appdata.xml -t $out/share/appdata/
      install -D extra/logo/compat/alacritty-term.svg $out/share/icons/hicolor/scalable/apps/Alacritty.svg

      # patchelf generates an ELF that binutils' "strip" doesn't like:
      #    strip: not enough room for program headers, try linking with -N
      # As a workaround, strip manually before running patchelf.
      $STRIP -S $out/bin/alacritty

      patchelf --set-rpath "${lib.makeLibraryPath rpathLibs}" $out/bin/alacritty
    ''
  ) + ''

    installShellCompletion --zsh extra/completions/_alacritty
    installShellCompletion --bash extra/completions/alacritty.bash
    installShellCompletion --fish extra/completions/alacritty.fish

    install -dm 755 "$out/share/man/man1"
    install -dm 755 "$out/share/man/man5"
    scdoc <extra/man/alacritty.1.scd | \
      gzip -c >"$out/share/man/man1/alacritty.1.gz"
    scdoc <extra/man/alacritty-msg.1.scd | \
      gzip -c >"$out/share/man/man1/alacritty-msg.1.gz"
    scdoc <extra/man/alacritty.5.scd | \
      gzip -c >"$out/share/man/man5/alacritty.5.gz"
    scdoc <extra/man/alacritty-bindings.5.scd | \
      gzip -c >"$out/share/man/man5/alacritty-bindings.5.gz"

    install -dm 755 "$terminfo/share/terminfo/a/"
    tic -xe alacritty,alacritty-direct -o "$terminfo/share/terminfo" extra/alacritty.info
    mkdir -p $out/nix-support
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  dontPatchELF = true;

  passthru.tests.test = nixosTests.terminal-emulators.alacritty;

  meta = with lib; {
    description = "A cross-platform, GPU-accelerated terminal emulator";
    homepage = "https://github.com/alacritty/alacritty";
    license = licenses.asl20;
    maintainers = with maintainers; [ Br1ght0ne mic92 ];
    platforms = platforms.unix;
    changelog = "https://github.com/alacritty/alacritty/blob/v${version}/CHANGELOG.md";
  };
}
