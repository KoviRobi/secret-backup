{
  nixpkgs ? import <nixpkgs> { },
}:

with nixpkgs;
mkShell {
  buildInputs = [
    paperkey
    qrencode
    imagemagick
    zbar
    (python3.withPackages (pypkgs: [ pypkgs.pillow ]))
  ];
}
