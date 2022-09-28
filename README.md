# svelte-webgpu

Play here: https://svelte-webgpu.vercel.app

Based on the raw WebGPU examples in the [references](#references).

## Svelte port

Built using [SvelteKit](https://kit.svelte.dev).

## Building svelte-knobby submodule

Currently using my fork of [svelte-knobby](https://github.com/jpaquim/svelte-knobby) while waiting for [this upstream PR](https://github.com/Rich-Harris/svelte-knobby/pull/29) to be integrated.

```bash
git submodule update --init
```

```bash
pushd packages/svelte-knobby && npm i && npm run build && npm run package; popd
```

## Developing

Install dependencies with `pnpm i`, start a development server:

```bash
pnpm dev

# or start the server and open the app in a new browser tab
pnpm dev --open
```

## Building

To create a production version of the app:

```bash
pnpm build
```

You can preview the production build with `pnpm preview`.

> To deploy your app, you may need to install an [adapter](https://kit.svelte.dev/docs/adapters) for your target environment.

## References

- Article by Surma: [WebGPU — All of the cores, none of the canvas](https://surma.dev/things/webgpu/index.html), source [here](https://github.com/surma/surma.dev/tree/master/static/things/webgpu)
- Article by Alain Galvan: [Raw WebGPU](https://alain.xyz/blog/raw-webgpu), source [here](https://github.com/alaingalvan/webgpu-seed)

## License

The code is available under the [MIT license](LICENSE)
