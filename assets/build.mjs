// assets/build.mjs
// esbuild entry that compiles Svelte components (Svelte Flow) alongside the
// plain JS app. Run via `node assets/build.mjs` from the repo root, or
// `node build.mjs` from inside assets/. Wired into mix assets.build.
import { fileURLToPath } from "url";
import path from "path";
import esbuild from "esbuild";

const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const watch = args.includes("--watch");

const options = {
  entryPoints: [path.join(here, "js/app.js")],
  bundle: true,
  outdir: path.join(here, "../priv/static/assets"),
  absWorkingDir: here,
  // Phoenix deps live in ../deps (the original esbuild config set NODE_PATH there).
  nodePaths: [path.join(here, "../deps")],
  target: "es2017",
  external: ["/fonts/*", "/images/*"],
  logLevel: "info",
};

if (watch) {
  const ctx = await esbuild.context(options);
  await ctx.watch();
  console.log("watching...");
} else {
  esbuild.build(options).catch(() => process.exit(1));
}
