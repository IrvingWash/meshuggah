Texture :: struct {
    id: u32;

    width:  u32;
    height: u32;
}

Texture_Kind :: enum {
    DIFFUSE;
}

create_2D_texture :: (path: string, kind: Texture_Kind) -> Texture {
    texture: Texture;

    image := load_image(path);
    defer destroy_image(*image);

    texture.width  = cast(u32, image.width);
    texture.height = cast(u32, image.height);

    using gl;

    glGenTextures(1, *texture.id);

    glBindTexture(GL_TEXTURE_2D, texture.id);
    defer glBindTexture(GL_TEXTURE_2D, 0);

    store_format: GLint;
    format:       GLenum;
    if image.format == {
        case .RGB;
            format = GL_RGB;
            store_format = ifx kind == .DIFFUSE
                then cast(s32, GL_SRGB8)
                else cast(s32, GL_RGB);
        case .RGBA;
            format = GL_RGBA;
            store_format = ifx kind == .DIFFUSE
                then cast(s32, GL_SRGB8_ALPHA8)
                else cast(s32, GL_RGBA);
    }

    glTexImage2D(
        GL_TEXTURE_2D,
        0, // Mipmap level - topmost
        store_format,
        cast(GLsizei, image.width),
        cast(GLsizei, image.height),
        0, // "Some legacy stuff" (c)
        format,
        GL_UNSIGNED_BYTE,
        image.data,
    );

    glGenerateMipmap(GL_TEXTURE_2D);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    return texture;
}

destroy_texture :: (texture: *Texture) {
    using gl;

    glDeleteTextures(1, *texture.id);

    texture.* = {};
}



#scope_module

bind_texture :: (texture: Texture, unit: u32 = 0) {
    using gl;

    glActiveTexture(GL_TEXTURE0 + cast(GLenum, unit));

    glBindTexture(GL_TEXTURE_2D, texture.id);
}

unbind_texture :: () {
    glActiveTexture(GL_TEXTURE0);

    glBindTexture(GL_TEXTURE_2D, 0);
}



#scope_file

Image :: struct {
    width:  s32;
    height: s32;

    format: Image_Format;

    data: *u8;
}

Image_Format :: enum {
    RGB;
    RGBA;
}

load_image :: (path: string) -> Image {
    image: Image;

    stbi_set_flip_vertically_on_load(cast(s32, true));

    c_path := temp_c_string(path);

    channel_count: s32;
    image.data = stbi_load(c_path, *image.width, *image.height, *channel_count, 0);
    assert(image.data != null, "Failed to load image from %", path);

    if channel_count == {
        case 3;
            image.format = .RGB;
        case 4;
            image.format = .RGBA;
        case;
            assert(false, "Unsupported image channel count %", channel_count);
    }

    return image;
}

destroy_image :: (image: *Image) {
    stbi_image_free(image.data);

    image.* = {};
}

#import "Basic";
#import "stb_image";
#import "GL";
