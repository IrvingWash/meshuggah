#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUV;

uniform mat4 uModelTransform;

uniform mat4 uProjectionTransform;
uniform mat4 uViewTransform;

out FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

void main()
{
    vec4 worldPosition = uModelTransform * vec4(aPosition, 1);

    gl_Position = uProjectionTransform * uViewTransform * worldPosition;

    fragmentData.normal = aNormal;
    fragmentData.uv = aUV;
}
