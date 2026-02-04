#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUV;
layout (location = 3) in vec4 aTint;
layout (location = 4) in mat4 aModelTransform;
layout (location = 8) in mat3 aNormalTransform;

uniform mat4 uProjectionTransform;
uniform mat4 uViewTransform;

out FragmentData
{
    vec3 normal;
    vec2 uv;
    vec4 tint;
} fragmentData;

void main()
{
    vec4 worldPosition = aModelTransform * vec4(aPosition, 1);

    gl_Position = uProjectionTransform * uViewTransform * worldPosition;

    fragmentData.normal = aNormalTransform * aNormal;
    fragmentData.uv = aUV;
    fragmentData.tint = aTint;
}
