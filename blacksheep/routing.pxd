# cython: language_level=3, embedsignature=True
# Copyright (C) 2018-present Roberto Prevato
#
# This module is part of BlackSheep and is released under
# the MIT License https://opensource.org/licenses/MIT


cdef class RouteException(Exception):
    pass


cdef class RouteDuplicate(RouteException):
    pass


cdef class RouteMatch:
    cdef readonly object handler
    cdef readonly dict values


cdef class Route:
    cdef public object handler
    cdef readonly bytes pattern
    cdef readonly bint has_params
    cdef object rx

    cpdef RouteMatch match(self, bytes value)


cdef class Router:
    cdef readonly dict routes
    cdef dict map
    cdef Route _fallback

    cpdef bint is_route_configured(self, bytes method, bytes pattern)

    cpdef RouteMatch get_match(self, bytes method, bytes path)
