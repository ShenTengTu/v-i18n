__all__ = ["field_meta", "extend_dataclass"]

import functools
from dataclasses import fields, _asdict_inner, _is_dataclass_instance


def field_meta(alias: str = None):
    """Field metadata for `@extend_dataclass` decorator.

    - `alias`: Field alias
    """
    metadata = {}
    _metadata = metadata.setdefault("extend_dataclasses", {})
    if type(alias) is str:
        _metadata["alias"] = alias
    return metadata


def _process_class(cls):
    original_init = cls.__init__

    @functools.wraps(cls.__init__)
    def _class_init(self, *args, **kwargs):
        # get value from alias
        kw = {}
        for field in fields(cls):
            if field.name in kwargs:
                kw[field.name] = kwargs[field.name]
                continue
            extend_meta = field.metadata.get("extend_dataclasses", {})
            alias = extend_meta.get("alias")
            if alias in kwargs:
                kw[field.name] = kwargs[alias]
        original_init(self, *args, **kw)

    cls.__init__ = _class_init

    return cls


def extend_dataclass(_cls=None):
    """Decorator for extend original dataclass."""

    def wrap(cls):
        return _process_class(cls)

    if _cls is None:
        return wrap
    return wrap(_cls)


def as_dict(obj, ignore_none=True):
    if _is_dataclass_instance(obj):
        result = []
        for field in fields(obj):
            extend_meta = field.metadata.get("extend_dataclasses", {})
            alias = extend_meta.get("alias", field.name)
            value = _asdict_inner(getattr(obj, field.name), dict)
            if ignore_none and value is None:
                continue
            result.append((alias, value))
        return dict(result)
