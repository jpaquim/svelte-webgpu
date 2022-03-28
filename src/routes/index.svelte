<script>
	import { onMount } from 'svelte';

	onMount(async () => {
		if (!navigator.gpu) throw Error('WebGPU not supported.');

		const adapter = await navigator.gpu.requestAdapter();
		if (!adapter) throw Error('Couldn’t request WebGPU adapter.');

		const device = await adapter.requestDevice();
		if (!device) throw Error('Couldn’t request WebGPU logical device.');

		const module = device.createShaderModule({
			code: `
        @stage(compute) @workgroup_size(64)
        fn main() {
          // Pointless!
        }
      `
		});

		const pipeline = device.createComputePipeline({
			compute: {
				module,
				entryPoint: 'main'
			}
		});

		const commandEncoder = device.createCommandEncoder();
		const passEncoder = commandEncoder.beginComputePass();
		passEncoder.setPipeline(pipeline);
		passEncoder.dispatch(1);
		passEncoder.end();
		const commands = commandEncoder.finish();
		device.queue.submit([commands]);
	});
</script>

<h1>Welcome to SvelteKit</h1>
<p>Visit <a href="https://kit.svelte.dev">kit.svelte.dev</a> to read the documentation</p>
