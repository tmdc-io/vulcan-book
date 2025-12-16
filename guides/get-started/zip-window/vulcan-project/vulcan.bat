@echo off
docker run -it --network=vulcan --rm -v %cd%:/workspace tmdcio/vulcan:0.225.0-dev-02 vulcan %*

