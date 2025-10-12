#!/usr/bin/env bash
set -e

echo "Running pub get in subdirectories..."

echo "Running pub get in directory $PWD/server..."
    (cd server && dart pub get)
echo ""

echo "Running pub get in directory $PWD/references_models..."
    (cd references_models && dart pub get)
echo ""

echo "Running pub get in directory $PWD/webapp..."
    (cd webapp && flutter pub get)
echo ""

echo "Enabling Flutter web for $PWD/webapp..."
    (cd webapp && flutter config --enable-web)
echo ""