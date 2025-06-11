##!/bin/sh

xcrun xcodebuild docbuild \
    -scheme Northstar \
    -destination 'platform=visionOS Simulator,name=Apple Vision Pro,OS=2.2' \
    -derivedDataPath "$PWD/.derivedData"

xcrun docc process-archive transform-for-static-hosting \
    "$PWD/.derivedData/Build/Products/Debug-xros/Axys.doccarchive" \
    --output-path ".docs" \
    --hosting-base-path "Axys"
