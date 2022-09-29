<script>
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import shader from './shader.wgsl?raw';

	export let NUM_BALLS = 1000;
	export let minRadius = 2;
	export let maxRadius = 10;
	export let width = 500;
	export let height = 500;

	$: BUFFER_SIZE = NUM_BALLS * 6 * Float32Array.BYTES_PER_ELEMENT;

	/** @param a {number}
	 * @param b {number} */
	const random = (a, b) => Math.random() * (b - a) + a;

	/** @type {HTMLCanvasElement}*/
	let canvas;
	/** @type {CanvasRenderingContext2D}*/
	let ctx;

	/** @type {GPUDevice}*/
	let device;
	/** @type {GPUComputePipeline}*/
	let pipeline;
	/** @type {GPUBindGroupLayout}*/
	let bindGroupLayout;
	/** @type {GPUBuffer}*/
	let scene;

	/** @type {number}*/
	let rafHandle;

	function cancelRaf() {
		cancelAnimationFrame(rafHandle);
	}

	/** @param {Float32Array} balls */
	function drawScene(balls) {
		ctx.save();
		ctx.scale(1, -1);
		ctx.translate(0, -height);
		ctx.clearRect(0, 0, width, height);
		ctx.fillStyle = 'red';
		for (let i = 0; i < balls.length; i += 6) {
			const r = balls[i + 0];
			const px = balls[i + 2];
			const py = balls[i + 3];
			const vx = balls[i + 4];
			const vy = balls[i + 5];
			let angle = Math.atan(vy / (vx === 0 ? Number.EPSILON : vx));
			// Correct for Math.atan() assuming the angle is [-PI/2;PI/2].
			if (vx < 0) angle += Math.PI;
			const ex = px + Math.cos(angle) * Math.sqrt(2) * r;
			const ey = py + Math.sin(angle) * Math.sqrt(2) * r;
			ctx.beginPath();
			ctx.arc(px, py, r, 0, 2 * Math.PI, true);
			ctx.moveTo(ex, ey);
			ctx.arc(px, py, r, angle - Math.PI / 4, angle + Math.PI / 4, true);
			ctx.lineTo(ex, ey);
			ctx.closePath();
			ctx.fill();
		}
		ctx.restore();
	}

	onMount(async () => {
		ctx = canvas.getContext('2d');

		if (!navigator.gpu) throw Error('WebGPU not supported.');

		const adapter = await navigator.gpu.requestAdapter();
		if (!adapter) throw Error('Couldn’t request WebGPU adapter.');

		device = await adapter.requestDevice();
		if (!device) throw Error('Couldn’t request WebGPU logical device.');

		const module = device.createShaderModule({ code: shader });

		bindGroupLayout = device.createBindGroupLayout({
			entries: [
				{
					binding: 0,
					visibility: GPUShaderStage.COMPUTE,
					buffer: { type: 'read-only-storage' }
				},
				{
					binding: 1,
					visibility: GPUShaderStage.COMPUTE,
					buffer: { type: 'storage' }
				},
				{
					binding: 2,
					visibility: GPUShaderStage.COMPUTE,
					buffer: { type: 'read-only-storage' }
				}
			]
		});

		pipeline = device.createComputePipeline({
			layout: device.createPipelineLayout({
				bindGroupLayouts: [bindGroupLayout]
			}),
			compute: {
				module,
				entryPoint: 'main'
			}
		});

		scene = device.createBuffer({
			size: 2 * Float32Array.BYTES_PER_ELEMENT,
			usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
		});
	});

	onDestroy(() => {
		browser && cancelRaf();
	});

	$: device?.queue.writeBuffer(scene, 0, new Float32Array([width, height]));

	$: if (device) {
		const input = device.createBuffer({
			size: BUFFER_SIZE,
			usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
		});

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
			entries: [
				{ binding: 0, resource: { buffer: input } },
				{ binding: 1, resource: { buffer: output } },
				{ binding: 2, resource: { buffer: scene } }
			]
		});

		let inputBalls = new Float32Array(new ArrayBuffer(BUFFER_SIZE));
		for (let i = 0; i < NUM_BALLS; ++i) {
			inputBalls[i * 6 + 0] = random(minRadius, maxRadius);
			// inputBalls[i * 6 + 1] = 0; // padding
			inputBalls[i * 6 + 2] = random(0, width); // position.x
			inputBalls[i * 6 + 3] = random(0, height); // position.y
			inputBalls[i * 6 + 4] = random(-100, 100); // velocity.x
			inputBalls[i * 6 + 5] = random(-100, 100); // velocity.y
		}

		// cancel any current raf, indirection to avoid reactivity with rafHandle
		cancelRaf();
		rafHandle = requestAnimationFrame(async function rafCallback() {
			device.queue.writeBuffer(input, 0, inputBalls);

			const commandEncoder = device.createCommandEncoder();
			const passEncoder = commandEncoder.beginComputePass();
			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.dispatchWorkgroups(Math.ceil(BUFFER_SIZE / 64));
			passEncoder.end();
			// passEncoder.endPass();
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
			const outputBalls = new Float32Array(data);

			drawScene(outputBalls);
			inputBalls = outputBalls;
			rafHandle = requestAnimationFrame(rafCallback);
		});
	}
</script>

<canvas {width} {height} bind:this={canvas} />

<style>
	canvas {
		outline: 1px solid black;
		max-width: 100vw;
		max-height: 100vh;
	}
</style>
