import re
from functools import lru_cache
from blacksheep import HttpMethod
from typing import Callable


_route_all_rx = re.compile(b'\\*')
_route_param_rx = re.compile(b'/:([^/]+)')
_named_group_rx = re.compile(b'\\?P<([^>]+)>')
_escaped_chars = {b'.', b'[', b']', b'(', b')'}


def _get_regex_for_pattern(pattern):

    for c in _escaped_chars:
        if c in pattern:
            pattern = pattern.replace(c, b'\\' + c)
    if b'*' in pattern:
        pattern = _route_all_rx.sub(br'(?P<tail>.+)', pattern)
    if b'/:' in pattern:
        pattern = _route_param_rx.sub(br'/(?P<\1>[^\/]+)', pattern)

    # NB: following code is just to throw user friendly errors
    # regex would fail anyway, but with a more complex message 'sre_constants.error: redefinition of group name'
    param_names = set()
    for p in _named_group_rx.finditer(pattern):
        param_name = p.group(1)
        if param_name in param_names:
            raise ValueError(f'cannot have multiple parameters with name: {param_name}')

        param_names.add(param_name)

    return re.compile(b'^' + pattern + b'$', re.IGNORECASE)


cdef class RouteException(Exception):
    pass


cdef class RouteDuplicate(RouteException):

    def __init__(self, method, pattern, current_handler):
        super().__init__(f'Cannot register route pattern `{pattern.decode()}` for `{method.decode()}` more than once. '
                         f'This pattern is already registered for handler `{current_handler.__name__}`.')


cdef class RouteMatch:
    def __init__(self, object handler, dict values):
        self.handler = handler
        self.values = values

    def __repr__(self):
        return f'<RouteMatch {id(self)}>'


cdef class Route:

    def __init__(self, bytes pattern, object handler):
        if pattern == b'':
            pattern = b'/'
        pattern = pattern.lower()
        self.handler = handler
        self.pattern = pattern.lower()
        self.has_params = b'*' in pattern or b':' in pattern
        self.rx = _get_regex_for_pattern(pattern)

    cpdef RouteMatch match(self, bytes value):
        if value.lower() == self.pattern:
            return RouteMatch(self.handler, None)

        match = self.rx.match(value)

        if not match:
            return None

        return RouteMatch(self.handler, dict(match.groupdict()) if self.has_params else None)

    def __repr__(self):
        return f'<Route {id(self)} {self.pattern}>'


cdef class Router:

    def __init__(self):
        self.map = {}
        self.routes = {}
        self._fallback = None

    @property
    def fallback(self):
        return self._fallback

    @fallback.setter
    def fallback(self, value):
        if not isinstance(value, Route):
            if callable(value):
                self._fallback = Route(b'*', value)
                return
            raise ValueError('fallback must be a Route')
        self._fallback = value

    def __iter__(self):
        cdef bytes key
        cdef list routes
        cdef Route route

        for key, routes in self.routes.items():
            for route in routes:
                yield route
        if self._fallback:
            yield self._fallback

    cpdef bint is_route_configured(self, bytes method, bytes pattern):
        cdef dict method_patterns
        
        method_patterns = self.map.get(method)
        if not method_patterns:
            return False
        if method_patterns.get(pattern):
            return True
        return False

    def _set_configured_route(self, method: bytes, pattern: bytes):
        method_patterns = self.map.get(method)
        if not method_patterns:
            self.map[method] = {pattern: True}
        else:
            method_patterns[pattern] = True

    def add(self, bytes method, object pattern, object handler):
        cdef Route new_route
        cdef RouteMatch current_match
        cdef bytes _pattern

        if isinstance(pattern, str):
            _pattern = pattern.encode()
        elif isinstance(pattern, bytes):
            _pattern = pattern
        else:
            raise ValueError('pattern must be bytes or str')
        
        new_route = Route(_pattern, handler)
        if self.is_route_configured(method, _pattern):
            current_match = self.get_match(method, _pattern)
            raise RouteDuplicate(method, _pattern, current_match.handler)
        else:
            self._set_configured_route(method, _pattern)
        self.add_route(method, new_route)

    def add_route(self, method, route):
        cdef list handlers
        try:
            handlers = self.routes[method]
        except KeyError:
            self.routes[method] = [route]
        else:
            handlers.append(route)

    def add_head(self, pattern, handler):
        self.add(b'HEAD', pattern, handler)

    def add_get(self, pattern, handler):
        self.add(b'GET', pattern, handler)

    def add_post(self, pattern, handler):
        self.add(b'POST', pattern, handler)

    def add_put(self, pattern, handler):
        self.add(b'PUT', pattern, handler)

    def add_delete(self, pattern, handler):
        self.add(b'DELETE', pattern, handler)

    def add_trace(self, pattern, handler):
        self.add(b'TRACE', pattern, handler)

    def add_options(self, pattern, handler):
        self.add(b'OPTIONS', pattern, handler)

    def add_connect(self, pattern, handler):
        self.add(b'CONNECT', pattern, handler)

    def add_patch(self, pattern, handler):
        self.add(b'PATCH', pattern, handler)

    def add_any(self, pattern, handler):
        self.add(b'*', pattern, handler)

    def head(self, pattern):
        def decorator(f):
            self.add(b'HEAD', pattern, f)
            return f
        return decorator

    def get(self, pattern):
        def decorator(f):
            self.add(b'GET', pattern, f)
            return f
        return decorator

    def post(self, pattern):
        def decorator(f):
            self.add(b'POST', pattern, f)
            return f
        return decorator

    def put(self, pattern):
        def decorator(f):
            self.add(b'PUT', pattern, f)
            return f
        return decorator

    def delete(self, pattern):
        def decorator(f):
            self.add(b'DELETE', pattern, f)
            return f
        return decorator

    def trace(self, pattern):
        def decorator(f):
            self.add(b'TRACE', pattern, f)
            return f
        return decorator

    def options(self, pattern):
        def decorator(f):
            self.add(b'OPTIONS', pattern, f)
            return f
        return decorator

    def connect(self, pattern):
        def decorator(f):
            self.add(b'CONNECT', pattern, f)
            return f
        return decorator

    def patch(self, pattern):
        def decorator(f):
            self.add(b'PATCH', pattern, f)
            return f
        return decorator

    @lru_cache(maxsize=1200)
    def _get_match(self, bytes method, bytes value):
        cdef Route
        cdef RouteMatch match

        for route in self.routes.get(method, []):
            match = route.match(value)
            if match:
                return match
        return RouteMatch(self._fallback.handler, None) if self._fallback else None

    cpdef RouteMatch get_match(self, bytes method, bytes value):
        return self._get_match(method, value)


cdef class BasicRouter(Router):

    def add_route(self, method, route):
        cdef bytes key = method + route.pattern
        self.map[key] = RouteMatch(route.handler, None)

    cpdef bint is_route_configured(self, bytes method, bytes pattern):
        cdef bytes key = method + pattern.lower()
        return key in self.map

    cpdef RouteMatch get_match(self, bytes method, bytes value):
        cdef bytes key = method + value.lower()
        return self.map.get(key, RouteMatch(self._fallback.handler, None) if self._fallback else None)

    def __iter__(self):
        cdef bytes key
        cdef RouteMatch route

        for key, route_match in self.map.values():
            yield (key, route_match)
