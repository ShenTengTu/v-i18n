## Update language subtag data
There are simple Python command line tool to update language subtag data for IANA language subtag registry.

1. Download remote language subtag registry then update locale `language-subtag-registry`
```
python -m py_cmd dl_registry
```

2. Update language subtag data in v files.
```
python -m py_cmd registry_to_v
```