const fs = require("fs");
const path = require("path");
const verbose = process.verbose;

function clearDirectory(directory) {
    const files = fs.readdirSync(directory);

    files.forEach((file) => {
        const filePath = path.join(directory, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
            clearDirectory(filePath);
            fs.rmdirSync(filePath);
        } else {
            fs.unlinkSync(filePath);
        }
    });
}

function copyDirectories(srcDir, destDir) {
    const files = fs.readdirSync(srcDir);
    files.forEach((file) => {
        const currentPath = path.join(srcDir, file);
        const targetPath = path.join(destDir, file);
        if (fs.statSync(currentPath).isDirectory()) {
            if (!fs.existsSync(targetPath)) {
                fs.mkdirSync(targetPath, { recursive: true });
            }
            copyDirectories(currentPath, targetPath);
        }
    });
}

function ensureUnsafeEvalHtml5(buildDir) {
    const indexPath = path.join(buildDir, "index.html");
    if (!fs.existsSync(indexPath)) return;
    let html = fs.readFileSync(indexPath, "utf8");
    const cspRegex = /<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]*)">/i;
    const match = html.match(cspRegex);
    if (!match) return;
    let content = match[1];
    if (!content.includes("script-src")) return;
    if (content.includes("'unsafe-eval'")) return;
    content = content.replace(/script-src\s+'self'/i, "script-src 'self' 'unsafe-eval'");
    html = html.replace(cspRegex, `<meta http-equiv="Content-Security-Policy" content="${content}">`);
    fs.writeFileSync(indexPath, html);
}

function ensureElectronReloadBridge(buildDir) {
    const electronPath = path.join(buildDir, "electron.js");
    if (fs.existsSync(electronPath)) {
        let electronJs = fs.readFileSync(electronPath, "utf8");
        if (!electronJs.includes("reload-window")) {
            electronJs += "\n\nelectron.ipcMain.on('reload-window', () => {\n\tif (mainWindow != null)\n\t\tmainWindow.webContents.reloadIgnoringCache();\n});\n";
            fs.writeFileSync(electronPath, electronJs);
        }
    }

    const preloadPath = path.join(buildDir, "preload.js");
    if (fs.existsSync(preloadPath)) {
        let preloadJs = fs.readFileSync(preloadPath, "utf8");
        if (!preloadJs.includes("electronHotload")) {
            preloadJs += "\n\nelectron.contextBridge.exposeInMainWorld(\n\t'electronHotload', {\n\t\treloadWindow: () => {\n\t\t\telectron.ipcRenderer.send('reload-window');\n\t\t}\n\t}\n);\n";
            fs.writeFileSync(preloadPath, preloadJs);
        }
    }
}

function getAllShaders(dirPath) {
    let files = [];

    const items = fs.readdirSync(dirPath);

    items.forEach((item) => {
        const fullPath = path.join(dirPath, item);
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory()) {
            files = files.concat(getAllShaders(fullPath));
        } else if (stat.isFile() && fullPath.endsWith(".glsl")) {
            files.push(fullPath);
        }
    });

    return files;
}

function assembleShaders(shaderDir, outputDir) {
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    } else {
        clearDirectory(outputDir);
    }
    copyDirectories(shaderDir, outputDir);

    const shaderFiles = getAllShaders(shaderDir);
    let shaderFilesRelative = [];
    for (const shaderFile of shaderFiles)
        shaderFilesRelative.push(path.relative(shaderDir, shaderFile));

    shaderFilesRelative.forEach((shaderFile) => {
        function assemble(shaderFile) {
            if (verbose) {
                console.log(`Processing shader: ${shaderFile}`);
            }

            const shaderPath = path.join(shaderDir, shaderFile);
            const outputPath = path.join(outputDir, shaderFile);

            if (!fs.existsSync(outputPath)) {
                const includeRegex = /^\s*#include\s+"(.+)"\s*$/gm;
                let shaderSource = fs.readFileSync(shaderPath, "utf8");
                let match;
                while ((match = includeRegex.exec(shaderSource)) !== null) {
                    const includePath = `${path.resolve(
                        outputDir,
                        match[1]
                    )}.glsl`;
                    if (!fs.existsSync(includePath)) {
                        try {
                            assemble(`${match[1]}.glsl`);
                        } catch (e) {
                            console.log(
                                `Failed to include: ${includePath}: ${e}`
                            );
                            return;
                        }
                    }

                    const includeContent = fs.readFileSync(includePath, "utf8");
                    shaderSource = shaderSource.replace(
                        match[0],
                        includeContent
                    );
                }

                fs.writeFileSync(outputPath, shaderSource, "utf8");
            }
        }

        assemble(shaderFile);
    });
}

const shaderInputDir = path.join(__dirname, "shaders");
const shaderOutputDir = path.join(process.cwd(), "build", "shaders_assembled");
assembleShaders(shaderInputDir, shaderOutputDir);

let project = new Project("s");
project.addSources("src");
project.addAssets("assets/**", {
    nameBaseDir: "assets",
    destination: "assets/{dir}/{name}",
    name: "{name}",
});

// asset types
process.assetTypes = process.assetTypes ?? {}
process.assetTypes["font"] = {
    type: "s.assets.internal.font.Font", 
    formats:{
        "ttf": "s.assets.internal.font.format.TTF"
    }
};
process.assetTypes["image"] = {
    type: "s.assets.internal.image.Image", 
    formats:{
        "bmp": "s.assets.internal.image.format.BMP",
        "exr": "s.assets.internal.image.format.EXR",
        "hdr": "s.assets.internal.image.format.HDR",
        "jpg": "s.assets.internal.image.format.JPG",
        "png": "s.assets.internal.image.format.PNG",
        "psd": "s.assets.internal.image.format.PSD",
        "tga": "s.assets.internal.image.format.TGA",
        "tif": "s.assets.internal.image.format.TIF",
    }
};

for (const [k, v] of Object.entries(process.assetTypes)) {
    var formats = [];
    for ([e, t] of Object.entries(v.formats))
        formats.push({extension: e, type: t});
    project.addParameter(`--macro s.macro.AssetsMacro.addAssetType("${k}", "${v.type}", ${JSON.stringify(formats)})`);
}

// markup shortcuts
for (const [k, v] of Object.entries(process.shortcuts ?? {})) {
    if (typeof k !== "string" || typeof v !== "string" || !v) continue;
    project.addParameter(
        `--macro s.ui.macro.ElementMacro.useShortcut(${JSON.stringify(k)}, ${JSON.stringify(v)})`
    );
}

// defines
let defs = [];
for (const def of (process.defines ?? [])) {
    let kv = def.split(" ");
    if (kv.length === 2) {
        project.addDefine(`${kv[0]}=${kv[1]}`);
        defs.push(`${kv[0]} ${kv[1]}`);
    } else {
        project.addDefine(def);
        defs.push(`${kv[0]} 1`);
    }
}

// shaders
project.addShaders(`${shaderOutputDir}/**/*{frag,vert}.glsl`, { defines: defs });

// libraries
project.localLibraryPath = "libs";
project.addLibrary("slog");
project.addLibrary("snet");
project.addLibrary("sshortcut");
project.addLibrary("sextensions");

const hotloadEnabled = process.argv.includes("--watch") || process.argv.includes("--hotload");

// hotload
if (hotloadEnabled) { 
    project.addDefine('hotload');
    // allow eval in electron
	project.targetOptions.html5.unsafeEval = true;
    // to support constructors patching, optional
	project.addDefine('js_classic'); 
    // client code for code-patching
    const buildDir = path.join(path.resolve('.'), 'build', platform);
    callbacks.postBuild = () => {
        ensureUnsafeEvalHtml5(buildDir);
        ensureElectronReloadBridge(buildDir);
    };
    callbacks.postHaxeCompilation = () => {
        ensureUnsafeEvalHtml5(buildDir);
        ensureElectronReloadBridge(buildDir);
    };
    if (process.argv.includes("--watch")) {
    	// start websocket server that will send type diffs to client
    	const { Server } = require("./server.js");
    	// path to target build folder and main js file.
    	const server = new Server(`${path.resolve('.')}/build/${platform}`, 'kha.js');
        callbacks.onFailure = (error) => {
            const message = error && error.stack ? error.stack : String(error);
            server.reportError(message);
        };
        // parse js file every compilation
     	callbacks.postHaxeRecompilation = () => {
            ensureUnsafeEvalHtml5(buildDir);
            ensureElectronReloadBridge(buildDir);
            server.reload();
        };
    	// for assets reloading
    	callbacks.postAssetReexporting = (path) => server.reloadAsset(path);
    }
}

// subprojects
await project.addProject("libs/aura");

resolve(project);
