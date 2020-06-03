# _*_ coding: utf-8 _*_
"""Validators for ``pydantic`` Custom DataType"""
from pathlib import Path
from pydantic import BaseModel
from .fhirabstractmodel import FHIRAbstractModel

__author__ = "Md Nazrul Islam<email2nazrul@gmail.com>"


def get_fhir_model_class(type_name: str) -> BaseModel:
    try:
        return globals()[type_name]
    except KeyError:
        raise LookupError(
            f"'{__name__}.{type_name}' doesnt found. "
            f"Should be imported from '{type_name.lower()}.{type_name}'"
        )


def fhir_model_validator(cls, v):
    """ """
    model_class = get_fhir_model_class(cls.__resource_type__)
    if isinstance(v, (str, bytes)):
        v = model_class.parse_raw(v)
    elif isinstance(v, Path):
        v = model_class.parse_file(v)
    elif isinstance(v, dict):
        v = model_class.parse_obj(v)
    if not isinstance(v, FHIRAbstractModel):
        raise ValueError()
    if cls.__resource_type__ != v.resourceType:
        raise ValueError
    return v
