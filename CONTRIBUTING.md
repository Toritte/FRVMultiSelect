# Build from source
Use Python 3.10 or newer. The builder uses only the standard library.

```sh
python scripts/build.py
```

To run the tests, install requirements-dev.txt, then run:
```sh
python -m unittest discover -s tests -v
```
The loader is a separate user dependency and is never bundled. See THIRD_PARTY.md for source attribution and redistribution terms.
