#! /bin/sh

rm -rfv $(find . -name "*.pyc")
rm -rfv $(find . -name "__pycache__")
rm -rfv 'dendropy/test/output/'*
rm -rfv 'dendropy/test/coverage/'*
#rm -rfv DendroPy.egg-info
rm -rfv build
rm -rfv dist
