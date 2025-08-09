#include <string>

#include <boost/property_tree/ptree.hpp>
#include <valhalla/config.h>
#include <valhalla/tyr/actor.h>
#include <valhalla/worker.h>

#include "valhalla_actor.h"

ValhallaActor *valhalla_actor_create(const char *config_string) {
  std::string config_cpp(config_string);
  boost::property_tree::ptree config = valhalla::config(config_string);
  return reinterpret_cast<ValhallaActor *>(new valhalla::tyr::actor_t(config));
}

void valhalla_actor_destroy(ValhallaActor *a) {
  delete reinterpret_cast<valhalla::tyr::actor_t *>(a);
}

const char *valhalla_actor_act(ValhallaActor *a, enum ValhallaAction action,
                               const char *request) {
  auto *actor = reinterpret_cast<valhalla::tyr::actor_t *>(a);
  std::string request_str(request);

  // do the right action
  valhalla::Api api;
  std::string response;
  try {
    switch (action) {
    case ROUTE:
      response = actor->route(request_str, nullptr, &api);
      break;
    case LOCATE:
      response = actor->locate(request_str, nullptr, &api);
      break;
    case SOURCES_TO_TARGETS:
      response = actor->matrix(request_str, nullptr, &api);
      break;
    case OPTIMIZED_ROUTE:
      response = actor->optimized_route(request_str, nullptr, &api);
      break;
    case ISOCHRONE:
      response = actor->isochrone(request_str, nullptr, &api);
      break;
    case TRACE_ROUTE:
      response = actor->trace_route(request_str, nullptr, &api);
      break;
    case TRACE_ATTRIBUTES:
      response = actor->trace_attributes(request_str, nullptr, &api);
      break;
    case HEIGHT:
      response = actor->height(request_str, nullptr, &api);
      break;
    case TRANSIT_AVAILABLE:
      response = actor->transit_available(request_str, nullptr, &api);
      break;
    case EXPANSION:
      response = actor->expansion(request_str, nullptr, &api);
      break;
    case STATUS:
      response = actor->status(request_str, nullptr, &api);
      break;
    default:
      response = "Unknown action";
    }
  } // api processing error specific error condition
  catch (const valhalla::valhalla_exception_t &ve) {
    response = valhalla::serialize_error(ve, api);
  } // it was a regular exception!?
  catch (const std::exception &e) {
    response = serialize_error({599, std::string(e.what())}, api);
  } // anything else
  catch (...) {
    response =
        serialize_error({599, std::string("Unknown exception thrown")}, api);
  }

  // we are done
  char *output = new char[response.size() + 1];
  strcpy(output, response.c_str());
  return output;
}