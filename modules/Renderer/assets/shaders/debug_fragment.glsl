#version 330 core

// In

in FragmentData
{
    vec4 color;
} fragmentData;

// Out

out vec4 fragmendColor;

void main()
{
    fragmendColor = fragmentData.color;
}
