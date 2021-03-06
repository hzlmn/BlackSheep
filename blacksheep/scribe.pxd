# cython: language_level=3
# Copyright (C) 2018-present Roberto Prevato
#
# This module is part of BlackSheep and is released under
# the MIT License https://opensource.org/licenses/MIT

from .headers cimport Headers, Header
from .contents cimport Content
from .cookies cimport Cookie
from .messages cimport Request, Response


cpdef bytes get_status_line(int status)

cpdef bint is_small_request(Request request)

cpdef bytes write_small_request(Request request)

cdef bint is_small_response(Response response)

cdef bytes write_small_response(Response response)

