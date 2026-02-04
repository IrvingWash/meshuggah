#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;

uniform mat4 uProjectionTransform;
uniform mat4 uViewTransform;

out FragmentData
{
    vec4 color;
} fragmentData;

void main()
{
    fragmentData.color = aColor;

    gl_Position = uProjectionTransform * uViewTransform * vec4(aPosition, 1.0);
}
