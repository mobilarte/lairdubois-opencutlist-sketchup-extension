#include <imagy.h>

#ifdef __cplusplus
extern "C" {
#endif

Image image;

DLL_EXPORTS void c_clear(void) {
  return image.clear();
}

DLL_EXPORTS int c_load(const char* filename) {
  return image.load(filename) ? 1 : 0;
}
DLL_EXPORTS int c_write(const char* filename) {
  return image.write(filename) ? 1 : 0;
}

DLL_EXPORTS int c_get_width(void) {
  return image.width;
}
DLL_EXPORTS int c_get_height(void) {
  return image.height;
}
DLL_EXPORTS int c_get_channels(void) {
  return image.channels;
}


DLL_EXPORTS void c_flip_horizontal(void) {
  image.flip(true);
}
DLL_EXPORTS void c_flip_vertical(void) {
  image.flip(false);
}


DLL_EXPORTS void c_rotate(int angle) {
  image.rotate(angle);
}


DLL_EXPORTS char* c_version(void) {
  return (char *)IMAGY_VERSION;
}

#ifdef __cplusplus
}
#endif