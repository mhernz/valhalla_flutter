#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT                                                      \
  __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum ValhallaAction { 
  ROUTE,
  LOCATE,
  SOURCES_TO_TARGETS,
  OPTIMIZED_ROUTE,
  ISOCHRONE,
  TRACE_ROUTE,
  TRACE_ATTRIBUTES,
  HEIGHT,
  TRANSIT_AVAILABLE,
  EXPANSION,
  STATUS
};

struct ValhallaActor;
typedef struct ValhallaActor ValhallaActor;
FFI_PLUGIN_EXPORT ValhallaActor *
valhalla_actor_create(const char *config_string);
FFI_PLUGIN_EXPORT void valhalla_actor_destroy(ValhallaActor *a);
FFI_PLUGIN_EXPORT const char *valhalla_actor_act(ValhallaActor *a,
                                                 enum ValhallaAction action,
                                                 const char *request);

#ifdef __cplusplus
}
#endif
