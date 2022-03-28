struct Ball {
  radius: f32;
  position: vec2<f32>;
  velocity: vec2<f32>;
}

@group(0) @binding(0)
var<storage, read> input: array<Ball>;

@group(0) @binding(1)
var<storage, write> output: array<Ball>;

let TIME_STEP: f32 = 0.016;

@stage(compute) @workgroup_size(64)
fn main(
  @builtin(global_invocation_id) global_id: vec3<u32>,
  @builtin(local_invocation_id) local_id : vec3<u32>,
) {
  let num_balls = arrayLength(&output);
  if (global_id.x >= num_balls) {
    return;
  }
  output[global_id.x] = input[global_id.x];
  output[global_id.x].position = input[global_id.x].position + input[global_id.x].velocity * TIME_STEP;
}
