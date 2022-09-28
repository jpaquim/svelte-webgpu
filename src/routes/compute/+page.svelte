<script>
	import * as knobby from 'svelte-knobby';
	import Canvas from './Canvas.svelte';

	const controls = knobby.panel({
		$id: 'main',
		NUM_BALLS: { min: 0, max: 10000, step: 10, value: 1000 },
		minRadius: { min: 1, max: 100, step: 1, value: 2 },
		maxRadius: { min: 1, max: 100, step: 1, value: 10 },
		width: { min: 32, max: 10000, step: 1, value: 500 },
		height: { min: 32, max: 10000, step: 1, value: 500 }
	});
</script>

<svelte:head>
	<title>Compute example</title>
	<meta name="description" content="WebGPU compute example" />
</svelte:head>

<Canvas {...$controls} />
