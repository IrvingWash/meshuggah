#version 330 core

layout (location = 0) in vec3 aPosition;

uniform mat4 uModelTransform;

void main()
{
    gl_Position = uModelTransform * vec4(aPosition, 1);
}
