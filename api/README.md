# Building API docs:

-   Install [Haxe](https://haxe.org/) and [dox](https://github.com/HaxeFoundation/dox)
-   Install [Node.js](https://nodejs.org/) (required by Kha `make.js`)
-   Open terminal at `sengine/api` _(`cd sengine/api`)_
-   Run `haxe build.hxml` to generate html into the `build/html/pages` directory

Notes:
-   `build.hxml` runs `prepare-kha-hxml.js`, which generates `../build/project-html5.hxml` locally.
-   If Kha cannot be auto-detected, set `KHA_PATH` to your Kha directory and rerun the command.
