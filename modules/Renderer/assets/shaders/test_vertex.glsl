#version 330 core

layout (location = 0) in vec3 aPosition;

uniform mat4 uModelTransform;

uniform mat4 uProjectionTransform;
uniform mat4 uViewTransform;

void main()
{
    vec4 worldPosition = uModelTransform * vec4(aPosition, 1);

    gl_Position = uProjectionTransform * uViewTransform * worldPosition;
}
