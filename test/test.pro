QT += core
QT -= gui

CONFIG += c++11
CONFIG -= flat

TARGET = test
CONFIG += console
CONFIG -= app_bundle

TEMPLATE = app

include($$PWD/../src/qcrashhandler.pri)

# create debug symbols for release builds
# NOTE : need to disable optimization, else dump files will point to incorrect source code lines
CONFIG *= force_debug_info
QMAKE_CXXFLAGS_RELEASE_WITH_DEBUGINFO -= -O2

SOURCES += main.cpp

include($$PWD/../deps/add_qt_path.pri)


