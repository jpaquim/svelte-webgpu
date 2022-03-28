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

		const bindGroupLayout = device.createBindGroupLayout({
			entries: [
				{
					binding: 1,
					visibility: GPUShaderStage.COMPUTE,
					buffer: { type: 'storage' }
				}
			]
		});

		const pipeline = device.createComputePipeline({
			layout: device.createPipelineLayout({
				bindGroupLayouts: [bindGroupLayout]
			}),
			compute: {
				module,
				entryPoint: 'main'
			}
		});

		const BUFFER_SIZE = 1000;

		const output = device.createBuffer({
			size: BUFFER_SIZE,
			usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
		});

		const stagingBuffer = device.createBuffer({
			size: BUFFER_SIZE,
			usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST
		});

		const bindGroup = device.createBindGroup({
			layout: bindGroupLayout,
			entries: [{ binding: 1, resource: { buffer: output } }]
		});

		const commandEncoder = device.createCommandEncoder();
		const passEncoder = commandEncoder.beginComputePass();
		passEncoder.setPipeline(pipeline);
		passEncoder.setBindGroup(0, bindGroup);
		passEncoder.dispatch(Math.ceil(BUFFER_SIZE / 64));
		passEncoder.end();
		commandEncoder.copyBufferToBuffer(
			output,
			0, // source offset
			stagingBuffer,
			0, // destination offset
			BUFFER_SIZE
		);
		const commands = commandEncoder.finish();
		device.queue.submit([commands]);

		await stagingBuffer.mapAsync(
			GPUMapMode.READ,
			0, // offset
			BUFFER_SIZE // length
		);

		const copyArrayBuffer = stagingBuffer.getMappedRange(0, BUFFER_SIZE);
		const data = copyArrayBuffer.slice(0);
		stagingBuffer.unmap();
		console.log(new Float32Array(data));
	});
</script>

<h1>Welcome to SvelteKit</h1>
<p>Visit <a href="https://kit.svelte.dev">kit.svelte.dev</a> to read the documentation</p>
