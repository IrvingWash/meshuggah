#version 330 core

// In

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUV;
layout (location = 3) in vec4 iTint;
layout (location = 4) in mat4 iModelTransform;
layout (location = 8) in mat3 iNormalTransform;

// Uniform

uniform mat4 uProjectionTransform;
uniform mat4 uViewTransform;

// Out

out FragmentData
{
    vec3 normal;
    vec2 uv;
    vec4 tint;
} fragmentData;

void main()
{
    vec4 worldPosition = iModelTransform * vec4(aPosition, 1);

    gl_Position = uProjectionTransform * uViewTransform * worldPosition;

    fragmentData.normal = iNormalTransform * aNormal;
    fragmentData.uv = aUV;
    fragmentData.tint = iTint;
}
