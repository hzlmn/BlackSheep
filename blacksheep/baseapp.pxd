# cython: language_level=3, embedsignature=True
# Copyright (C) 2018-present Roberto Prevato
#
# This module is part of BlackSheep and is released under
# the MIT License https://opensource.org/licenses/MIT
from .routing cimport Router
from .options cimport ServerOptions


cdef class BaseApplication:

    cdef readonly ServerOptions options
    cdef readonly Router router
    cdef readonly set connections
