# Aura from the official Linux package (`Aura_<version>_amd64.deb` on ordreth.com/apps/aura).
#
# Aura is closed source, so this does not build it: it unpacks the `.deb` the release workflow builds
# on Ubuntu, points the binary at nixpkgs' libraries (autoPatchelfHook) and wraps it with the GTK
# environment (wrapGAppsHook3). The version and the SHA-256 come from `sources.json`; `update.sh`
# changes them.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  alsa-lib,
  cairo,
  dbus,
  gdk-pixbuf,
  glib,
  glib-networking,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  webkitgtk_4_1,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "aura";
  inherit (sources) version;

  src = fetchurl {
    url = "https://ordreth.com/apps/aura/downloads/Aura_${finalAttrs.version}_amd64.deb";
    # Hex, as published in SHA256SUMS-linux.txt and on the download page.
    inherit (sources) sha256;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  # The libraries the binary links (readelf -d), plus the ones the source build wraps it with:
  # glib-networking (TLS for GIO) and the GStreamer plugins WebKitGTK looks for.
  buildInputs = [
    alsa-lib
    cairo
    dbus
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    (lib.getLib stdenv.cc.cc) # libgcc_s
    libsoup_3
    webkitgtk_4_1
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
  ]);

  # A .deb is an ar archive holding data.tar.gz; stdenv's binutils has `ar`, so no dpkg needed.
  unpackPhase = ''
    runHook preUnpack
    ar x "$src"
    mkdir root
    tar -xf data.tar.* -C root
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r root/usr/. "$out/"
    # Keep the license next to the program, where nixpkgs packages put it.
    mkdir -p "$out/share/licenses/aura"
    mv "$out/share/doc/aura/copyright" "$out/share/licenses/aura/LICENSE"
    rm -r "$out/share/doc"
    runHook postInstall
  '';

  # The tray icon loads libayatana-appindicator at run time (dlopen), so autoPatchelf cannot see it.
  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]})
  '';

  meta = {
    description = "A lightweight, customizable, offline-first music player";
    homepage = "https://ordreth.com/apps/aura";
    # Free to use, closed source, no redistribution (Aura's license agreement).
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "aura-player";
    # The only Linux build published is amd64.
    platforms = [ "x86_64-linux" ];
  };
})
