struct Ball {
  radius: f32;
  position: vec2<f32>;
  velocity: vec2<f32>;
}

@group(0) @binding(1)
var<storage, write> output: array<Ball>;

@stage(compute) @workgroup_size(64)
fn main(
  @builtin(global_invocation_id) global_id: vec3<u32>,
  @builtin(local_invocation_id) local_id : vec3<u32>,
) {
  let num_balls = arrayLength(&output);
  if (global_id.x >= num_balls) {
    return;
  }
  output[global_id.x].radius = 999.;
  output[global_id.x].position = vec2<f32>(global_id.xy);
  output[global_id.x].velocity = vec2<f32>(local_id.xy);
}
