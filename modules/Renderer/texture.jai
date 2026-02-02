Texture :: struct {
    id: u32;

    width:  u32;
    height: u32;
}

Texture_Usage :: enum {
    BASE_COLOR;
}

create_2D_texture :: (path: string, usage: Texture_Usage) -> Texture {
    wrap: GLint;
    should_generate_mipmaps: bool;
    should_store_as_srgb: bool;
    if #complete usage == {
        case Texture_Usage.BASE_COLOR;
            wrap = GL_REPEAT;
            should_generate_mipmaps = true;
            should_store_as_srgb = true;
    }

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
        case Image_Format.RGB;
            format = GL_RGB;
            store_format = ifx should_store_as_srgb
                then cast(s32, GL_SRGB8)
                else cast(s32, GL_RGB8);
        case Image_Format.RGBA;
            format = GL_RGBA;
            store_format = ifx should_store_as_srgb
                then cast(s32, GL_SRGB8_ALPHA8)
                else cast(s32, GL_RGBA8);
    }

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

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

    if should_generate_mipmaps {
        glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    } else {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap);

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

    c_path := temp_c_string(path);

    channel_count: s32;
    image.data = stbi_load(c_path, *image.width, *image.height, *channel_count, 0);
    assert(image.data != null, "Failed to load image from %", path);

    if channel_count == {
        case 3;
            image.format = Image_Format.RGB;
        case 4;
            image.format = Image_Format.RGBA;
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
