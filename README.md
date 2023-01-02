# ERiCman

ERiCman is a tool for downloading and managing elster rich client (ERiC) releases
from [elster.de](https://www.elster.de/elsterweb/entwickler/infoseite/eric).

Given an ERiC version ERiCman automatically

1. downloads the given release from
2. extracts the downloaded packages
3. creates a symlink from an `active` directory to the extracted files
4. creates bundles configured via the `bundle` folder
5. applies relevant patches to the bundles
6. executes install scripts

**Please note** that this script currently only has OS support for "Linux x86_64".

## Usage

Configure bundles / patches / install scripts (explained further down) and execute `./ericman.sh VERSION` with `VERSION`
taking the form of `37.2.6.0`.

Example:

```sh
./ericman 37.2.6.0 linux
```

## Bundles

Bundles are a way to collect files from an elster distribution. If for example you have a group of users that always
want all the _plausipruefungen_ files neatly placed into one single folder or for your software to work you need to
retrieve certain `.xsd` files, bundles provide an easy way to achieve this. When ERiCman runs, it collects all files
belonging to the bundle in a folder named after the bundle.

Have a look at the `bundles` subdirectory of this git repo to see some possible examples of useful bundles. In order to
activate them remove the `.example` suffix from the folder names.

### Creating a bundle

Any directory ending in `.bundle` inside the `bundle` subdirectory is considered to be a bundle.

To create a bundle, navigate to the `bundle` directory with your shell and create a folder named after the bundle you
would like to create.

Execute

```sh
mkdir -p bundle/example.bundle
```

to create a bundle called `example`.

### Adding files to bundles

If you want to add a file to a bundle, just create a symlink to `../../active/PATH_IN_ERIC_DISTRIBUTION` inside the
bundle directory.

Example: you want to add the ERiC license file located at (`Dokumentation/lizenz.pdf`) to your distribution.
Execute

```sh
ln -s ../../active/Dokumentation/lizenz.pdf example.bundle/
```

in order to add it.

### Changing the output directory

The output directory of ERiCman can be configured by setting the `ERICMAN_CONTEXT` environment variable. An easy way to
set it for one execution is to prepend it to the shell command:

```sh
ERICMAN_CONTEXT="${HOME}/.ericman" ./ericman 37.2.6.0
```

alternatively set it for the lifetime of the shell context using `export`

```sh
export ERICMAN_CONTEXT="${HOME}/.ericman"
```

and then execute ERiCman afterwards.

## Patches

Any `VERSION.patch` files with version matching that of the version ERiCman is invoked with get applied after copying
the bundle files.

Example: in order for `elster11_bisNH_extern.xsd` of version `37.2.6.0` to work with your xsd parser, you need to make
small adjustments to the file. Place an appropriate patch file named `elster11_bisNH_extern.xsd.37.2.6.0.patch` in your
bundle directory.

### Creating patches

The easiest way to create patches is to first run ERiCman to create your bundle and make the changes you would like to
have applied in the bundle output directory. Execute

```sh
git diff --no-index \
  active/Dokumentation/Schnittstellenbeschreibungen/ElsterBasisSchema/Schema/elster11_bisNH_extern.xsd \
  ERiC-37.2.6.0-grundsteuer-xsd/elster11_bisNH_extern.xsd \
  > bundle/grundsteuer-xsd.bundle/elster11_bisNH_extern.xsd.37.2.6.0.patch
```

to create the patch file. As you can see we are comparing the original version from the `active` directory with the
updated version in the bundle output directory. The diff output is then stored in the bundle source directory.

## Install files

Files called `.install` are executed after the bundle has been successfully built. This is useful if you want to do
further processing such as copying the bundled files to a different folder.

The output directory of the bundle is passed as the first argument (`$1`) to the `.install` script.

In order to activate the `.install` file in `grundsteuer-lib.bundle.example` set the executable bit on it:

```sh
chmod +x grundsteuer-lib.bundle.example/install.sh
```
