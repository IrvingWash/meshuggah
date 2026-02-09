Gyro_Ball :: struct {
    #as using entity: Entity;

    model_path = "assets/models/gyro_ball/gyro_ball.gltf";
}

spawn_gyro_ball :: () {
    gyro_ball: Gyro_Ball;

    gyro_ball.position = { -4, 1, 4 };

    spawn_entity(gyro_ball);
}
