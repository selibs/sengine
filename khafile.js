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
        `--macro s.ui.macro.MarkupMacro.useShortcut(${JSON.stringify(k)}, ${JSON.stringify(v)})`
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

// subprojects
await project.addProject("libs/aura");

resolve(project);
